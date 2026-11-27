import { lazy, Suspense, useState } from 'react'
import { Sheet } from '../../ui/Sheet'
import { Segmented } from '../../ui/controls'
import type { EntryItem } from '../../lib/nutrition'
import { currentMealType, type InputMethod, type MealType } from '../../lib/types'
import { BrowseFoods } from './BrowseFoods'
import { AiCapture } from './AiCapture'

// zxing is large; only load it when the barcode tab opens.
const BarcodeScan = lazy(() => import('./BarcodeScan').then((m) => ({ default: m.BarcodeScan })))
import { ReviewItems, type ReviewSource } from './ReviewItems'

export type LogMode = 'browse' | 'text' | 'voice' | 'photo' | 'barcode'
const MODES: readonly LogMode[] = ['browse', 'text', 'voice', 'photo', 'barcode']
const MODE_LABELS: Record<LogMode, string> = { browse: 'Browse', text: 'Text', voice: 'Voice', photo: 'Photo', barcode: 'Barcode' }

interface Pending { items: EntryItem[]; method: InputMethod; source: ReviewSource }

export function LogFood({ initialMode = 'browse', mealType, day, onClose, onAdded }: {
  initialMode?: LogMode; mealType?: MealType; day?: number; onClose: () => void; onAdded: () => void
}) {
  const [mode, setMode] = useState<LogMode>(initialMode)
  const [pending, setPending] = useState<Pending | null>(null)
  const meal = mealType ?? currentMealType()

  const review = (items: EntryItem[], method: InputMethod, source: ReviewSource = { kind: 'none' }) => setPending({ items, method, source })

  return (
    <Sheet title={pending ? 'Review' : `Log ${meal}`} onClose={onClose} full>
      {pending ? (
        <ReviewItems
          initialItems={pending.items} source={pending.source} method={pending.method}
          mealType={meal} day={day} onBack={() => setPending(null)} onSaved={onAdded}
        />
      ) : (
        <div className="stack">
          <Segmented options={MODES} value={mode} onChange={setMode} labels={MODE_LABELS} />
          {mode === 'browse' && <BrowseFoods onPick={(items) => review(items, 'Search')} />}
          {(mode === 'text' || mode === 'voice' || mode === 'photo') && (
            <AiCapture key={mode} kind={mode} onParsed={(items, source) => review(items, mode === 'text' ? 'Text' : mode === 'voice' ? 'Voice' : 'Photo', source)} />
          )}
          {mode === 'barcode' && <Suspense fallback={<div className="spinner" />}><BarcodeScan onFound={(item) => review([item], 'Barcode')} /></Suspense>}
        </div>
      )}
    </Sheet>
  )
}
