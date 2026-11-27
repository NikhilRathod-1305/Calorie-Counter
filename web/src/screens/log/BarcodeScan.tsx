import { useEffect, useRef, useState } from 'react'
import { BrowserMultiFormatReader, type IScannerControls } from '@zxing/browser'
import { lookupBarcode } from '../../lib/openFoodFacts'
import type { EntryItem } from '../../lib/nutrition'
import { ErrorBox, errorMessage } from '../../ui/controls'

export function BarcodeScan({ onFound }: { onFound: (item: EntryItem) => void }) {
  const video = useRef<HTMLVideoElement>(null)
  const [code, setCode] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [cameraError, setCameraError] = useState<string | null>(null)
  const found = useRef(false)

  const lookup = async (barcode: string) => {
    setBusy(true); setError(null)
    try {
      const p = await lookupBarcode(barcode)
      onFound({ name: p.name, base: p.per100g, servings: 1, servingLabel: '100g' })
    } catch (e) { setError(errorMessage(e)); found.current = false } finally { setBusy(false) }
  }

  useEffect(() => {
    let controls: IScannerControls | undefined
    let cancelled = false
    const reader = new BrowserMultiFormatReader()
    reader.decodeFromConstraints({ video: { facingMode: 'environment' } }, video.current!, (result) => {
      if (!result || found.current) return
      found.current = true
      void lookup(result.getText())
    }).then((c) => { if (cancelled) c.stop(); else controls = c })
      .catch((e) => setCameraError(`Camera unavailable: ${errorMessage(e)}. Type the barcode instead.`))
    return () => { cancelled = true; controls?.stop() }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div className="stack">
      {!cameraError && <div className="video-box"><video ref={video} muted playsInline /><div className="reticle" /></div>}
      <ErrorBox message={cameraError} />
      <div className="row">
        <input className="input" inputMode="numeric" placeholder="Or type the barcode number" value={code} onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))} aria-label="Barcode number" />
        <button className="btn btn-primary" disabled={busy || code.length < 6} onClick={() => lookup(code)}>Look up</button>
      </div>
      {busy && <div className="spinner" />}
      <ErrorBox message={error} />
      <div className="tiny faint center">Product data from Open Food Facts. Values are per 100 g/ml.</div>
    </div>
  )
}
