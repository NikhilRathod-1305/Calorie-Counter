import { useState } from 'react'
import { db } from '../../lib/db'
import { groupName } from '../../lib/meals'
import { entryTotal, itemTotal } from '../../lib/nutrition'
import { MEAL_TYPES, type MealEntry } from '../../lib/types'
import { fmtTime } from '../../lib/dates'
import { Sheet } from '../../ui/Sheet'
import { ErrorBox, Segmented, Stepper, errorMessage, useToast } from '../../ui/controls'

export function EditEntry({ entry, onClose }: { entry: MealEntry; onClose: () => void }) {
  const toast = useToast()
  const [draft, setDraft] = useState(entry)
  const [error, setError] = useState<string | null>(null)
  const total = entryTotal(draft)

  const setServings = (i: number, servings: number) => setDraft((d) => ({ ...d, items: d.items.map((it, j) => (j === i ? { ...it, servings } : it)) }))
  const removeItem = (i: number) => setDraft((d) => ({ ...d, items: d.items.filter((_, j) => j !== i) }))

  const save = async () => {
    try {
      if (draft.items.length === 0) await db.meals.delete(entry.id)
      else await db.meals.put({ ...draft, name: draft.items.length === entry.items.length ? draft.name : groupName(draft.items) })
      toast('Updated'); onClose()
    } catch (e) { setError(errorMessage(e)) }
  }
  const remove = async () => {
    try {
      await db.meals.delete(entry.id)
      toast(`Deleted ${entry.name}`, { label: 'Undo', onClick: () => void db.meals.put(entry) })
      onClose()
    } catch (e) { setError(errorMessage(e)) }
  }

  return (
    <Sheet title={entry.name} onClose={onClose}>
      <div className="stack">
        <div className="small muted">{fmtTime(entry.timestamp)} · {entry.inputMethod} · {Math.round(total.calories)} cal · P {Math.round(total.protein)}g · C {Math.round(total.carbs)}g · F {Math.round(total.fat)}g</div>
        <Segmented options={MEAL_TYPES} value={draft.mealType} onChange={(mealType) => setDraft((d) => ({ ...d, mealType }))} />
        <div className="card">
          {draft.items.map((it, i) => (
            <div className="list-row" key={i} style={{ gap: 8 }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14 }}>{it.name}</div>
                <div className="tiny faint">{Math.round(itemTotal(it).calories)} cal{it.servingLabel ? ` · ${it.servingLabel} per serving` : ''}</div>
              </div>
              <Stepper value={it.servings} onChange={(v) => setServings(i, v)} step={it.servingLabel === '100g' ? 0.25 : 0.5}
                format={(v) => (it.servingLabel === '100g' ? `${Math.round(v * 100)}g` : `${v}×`)} />
              {draft.items.length > 1 && <button className="del-btn" aria-label={`Remove ${it.name}`} onClick={() => removeItem(i)}>✕</button>}
            </div>
          ))}
        </div>
        <ErrorBox message={error} />
        <div className="grid-2">
          <button className="btn btn-danger" onClick={remove}>Delete</button>
          <button className="btn btn-primary" onClick={save}>Save</button>
        </div>
      </div>
    </Sheet>
  )
}
