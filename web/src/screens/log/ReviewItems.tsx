import { useState } from 'react'
import { parseFoodImage, parseFoodText, refineFood } from '../../lib/gemini'
import { loadApiKey } from '../../lib/settings'
import { addMealEntry } from '../../lib/meals'
import { entryTotal, itemTotal, type EntryItem } from '../../lib/nutrition'
import { MEAL_TYPES, type InputMethod, type MealType } from '../../lib/types'
import { onDay } from '../../lib/dates'
import { ErrorBox, Segmented, Stepper, errorMessage } from '../../ui/controls'

/** What to re-send to Gemini when the user asks for a correction. */
export type ReviewSource = { kind: 'text'; text: string } | { kind: 'photo'; jpeg: string } | { kind: 'none' }

export function ReviewItems({ initialItems, source, method, mealType, day, onBack, onSaved }: {
  initialItems: EntryItem[]; source: ReviewSource; method: InputMethod; mealType: MealType; day?: number; onBack: () => void; onSaved: () => void
}) {
  const [items, setItems] = useState(initialItems)
  const [meal, setMeal] = useState(mealType)
  const [refinement, setRefinement] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const isAi = method === 'Text' || method === 'Voice' || method === 'Photo'
  const total = entryTotal({ items })

  const update = (i: number, patch: Partial<EntryItem>) => setItems((prev) => prev.map((it, j) => (j === i ? { ...it, ...patch } : it)))
  const remove = (i: number) => setItems((prev) => prev.filter((_, j) => j !== i))

  const refine = async () => {
    setBusy(true); setError(null)
    try {
      const key = loadApiKey()
      const parsed = source.kind === 'photo' ? await parseFoodImage(key, source.jpeg, refinement)
        : source.kind === 'text' ? await parseFoodText(key, source.text, refinement)
        : await refineFood(key, items.map((i) => ({ name: i.name, nutrition: itemTotal(i) })), refinement)
      setItems(parsed.map((p) => ({ name: p.name, base: p.nutrition, servings: 1 })))
      setRefinement('')
    } catch (e) { setError(errorMessage(e)) } finally { setBusy(false) }
  }

  const save = async () => {
    setBusy(true); setError(null)
    try { await addMealEntry(items, meal, day === undefined ? Date.now() : onDay(day), method); onSaved() } catch (e) { setError(errorMessage(e)); setBusy(false) }
  }

  return (
    <div className="stack">
      <Segmented options={MEAL_TYPES} value={meal} onChange={setMeal} />
      <div className="card">
        {items.length === 0 && <div className="empty">All items removed.</div>}
        {items.map((it, i) => (
          <div className="list-row" key={i} style={{ gap: 8 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <input className="input" style={{ minHeight: 36, padding: '4px 8px', border: 'none', background: 'transparent', fontWeight: 600 }} value={it.name} onChange={(e) => update(i, { name: e.target.value })} aria-label="Food name" />
              <div className="tiny faint" style={{ paddingLeft: 8 }}>
                {Math.round(itemTotal(it).calories)} cal · P {Math.round(itemTotal(it).protein)} · C {Math.round(itemTotal(it).carbs)} · F {Math.round(itemTotal(it).fat)}
              </div>
            </div>
            <Stepper value={it.servings} onChange={(v) => update(i, { servings: v })} step={it.servingLabel === '100g' ? 0.25 : 0.5}
              format={(v) => (it.servingLabel === '100g' ? `${Math.round(v * 100)}g` : `${v}×`)} />
            <button className="del-btn" onClick={() => remove(i)} aria-label={`Remove ${it.name}`}>✕</button>
          </div>
        ))}
      </div>

      <div className="card card-pad row" style={{ justifyContent: 'space-around' }}>
        <Total label="Calories" value={total.calories} />
        <Total label="Protein" value={total.protein} unit="g" />
        <Total label="Carbs" value={total.carbs} unit="g" />
        <Total label="Fat" value={total.fat} unit="g" />
      </div>

      {isAi && (
        <div className="row">
          <input className="input" placeholder="Correct it, e.g. “the rice was 2 cups”" value={refinement} onChange={(e) => setRefinement(e.target.value)} aria-label="Correction" />
          <button className="btn btn-secondary" disabled={busy || !refinement.trim()} onClick={refine}>Fix</button>
        </div>
      )}
      <ErrorBox message={error} />
      <div className="grid-2">
        <button className="btn btn-secondary" onClick={onBack} disabled={busy}>Back</button>
        <button className="btn btn-primary" onClick={save} disabled={busy || items.length === 0}>{busy ? 'Working…' : 'Add to Diary'}</button>
      </div>
    </div>
  )
}

const Total = ({ label, value, unit = '' }: { label: string; value: number; unit?: string }) => (
  <div className="center"><div className="num bold" style={{ fontSize: 18 }}>{Math.round(value)}{unit}</div><div className="tiny muted">{label}</div></div>
)
