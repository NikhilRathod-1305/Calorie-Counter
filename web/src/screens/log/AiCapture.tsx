import { useEffect, useRef, useState } from 'react'
import { parseFoodAudio, parseFoodImage, parseFoodText, type ParsedFood } from '../../lib/gemini'
import { loadApiKey } from '../../lib/settings'
import { imageFileToJpegBase64 } from '../../lib/image'
import { MAX_RECORDING_SECONDS, recordingToWavBase64, startRecording, type Recorder } from '../../lib/audio'
import type { EntryItem } from '../../lib/nutrition'
import { ErrorBox, errorMessage } from '../../ui/controls'
import type { ReviewSource } from './ReviewItems'

const toItems = (parsed: ParsedFood[]): EntryItem[] => parsed.map((p) => ({ name: p.name, base: p.nutrition, servings: 1 }))

export function AiCapture({ kind, onParsed }: { kind: 'text' | 'voice' | 'photo'; onParsed: (items: EntryItem[], source: ReviewSource) => void }) {
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const hasKey = !!loadApiKey()

  const run = async (task: () => Promise<{ parsed: ParsedFood[]; source: ReviewSource }>) => {
    setBusy(true); setError(null)
    try {
      const { parsed, source } = await task()
      onParsed(toItems(parsed), source)
    } catch (e) { setError(errorMessage(e)) } finally { setBusy(false) }
  }

  if (!hasKey) return <div className="info-box">AI logging needs a free Gemini API key. Add it in <b>More → Gemini API Key</b>. You can get one at aistudio.google.com.</div>

  return (
    <div className="stack">
      {kind === 'text' && <TextInput busy={busy} onSubmit={(text) => run(async () => ({ parsed: await parseFoodText(loadApiKey(), text), source: { kind: 'text', text } }))} />}
      {kind === 'photo' && <PhotoInput busy={busy} onPhoto={(file) => run(async () => {
        const jpeg = await imageFileToJpegBase64(file)
        return { parsed: await parseFoodImage(loadApiKey(), jpeg), source: { kind: 'photo', jpeg } }
      })} />}
      {kind === 'voice' && <VoiceInput busy={busy} onError={setError} onAudio={(blob) => run(async () => {
        const wav = await recordingToWavBase64(blob)
        return { parsed: await parseFoodAudio(loadApiKey(), wav), source: { kind: 'none' } }
      })} />}
      {busy && <div className="center stack" style={{ gap: 8 }}><div className="spinner" /><span className="small muted">Estimating nutrition…</span></div>}
      <ErrorBox message={error} />
    </div>
  )
}

function TextInput({ busy, onSubmit }: { busy: boolean; onSubmit: (t: string) => void }) {
  const [text, setText] = useState('')
  return (
    <>
      <textarea className="input" placeholder="e.g. 2 rotis, a bowl of dal and a glass of lassi" value={text} onChange={(e) => setText(e.target.value)} aria-label="Describe what you ate" />
      <button className="btn btn-primary btn-block" disabled={busy || !text.trim()} onClick={() => onSubmit(text.trim())}>Estimate with AI</button>
    </>
  )
}

function PhotoInput({ busy, onPhoto }: { busy: boolean; onPhoto: (f: File) => void }) {
  const ref = useRef<HTMLInputElement>(null)
  return (
    <>
      <input ref={ref} type="file" accept="image/*" capture="environment" hidden onChange={(e) => { const f = e.target.files?.[0]; if (f) onPhoto(f); e.target.value = '' }} />
      <div className="card card-pad center stack" style={{ gap: 10 }}>
        <div style={{ fontSize: 56 }} aria-hidden="true">📸</div>
        <div className="muted small">Take a photo of your meal. Each item on the plate is estimated separately.</div>
        <button className="btn btn-primary btn-block" disabled={busy} onClick={() => ref.current?.click()}>Take or choose photo</button>
      </div>
    </>
  )
}

function VoiceInput({ busy, onAudio, onError }: { busy: boolean; onAudio: (b: Blob) => void; onError: (m: string) => void }) {
  const [recorder, setRecorder] = useState<Recorder | null>(null)
  const [seconds, setSeconds] = useState(0)
  const active = useRef<Recorder | null>(null)

  const stop = async () => {
    const r = active.current
    if (!r) return
    active.current = null
    setRecorder(null)
    onAudio(await r.stop())
  }
  const stopRef = useRef(stop)
  useEffect(() => { stopRef.current = stop })

  useEffect(() => {
    if (!recorder) return
    const started = Date.now()
    const t = window.setInterval(() => {
      const s = Math.floor((Date.now() - started) / 1000)
      setSeconds(s)
      if (s >= MAX_RECORDING_SECONDS) void stopRef.current()
    }, 250)
    return () => window.clearInterval(t)
  }, [recorder])
  // Release the microphone if the sheet closes mid-recording.
  useEffect(() => () => active.current?.cancel(), [])

  const start = async () => {
    try {
      setSeconds(0)
      const r = await startRecording()
      active.current = r
      setRecorder(r)
    } catch (e) { onError(`Microphone unavailable: ${errorMessage(e)}`) }
  }

  return (
    <div className="card card-pad center">
      <button className={`record-btn${recorder ? ' on' : ''}`} disabled={busy} onClick={recorder ? stop : start} aria-label={recorder ? 'Stop recording' : 'Start recording'}>
        {recorder ? '■' : '🎙️'}
      </button>
      <div className="muted small">{recorder ? `Listening… ${seconds}s, tap to finish` : 'Tap and say what you ate, e.g. “two eggs, toast and a coffee with milk”'}</div>
    </div>
  )
}
