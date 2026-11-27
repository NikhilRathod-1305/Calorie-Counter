import { useState } from 'react'
import { db } from '../../lib/db'
import type { Exercise } from '../../lib/types'
import { Sheet } from '../../ui/Sheet'
import { ErrorBox, errorMessage } from '../../ui/controls'
import { useAllExercises } from './exercises'

const CATEGORIES = ['Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core', 'Cardio', 'Full Body']

export function ExercisePicker({ onPick, onClose }: { onPick: (e: Exercise) => void; onClose: () => void }) {
  const all = useAllExercises()
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const q = query.trim().toLowerCase()
  const results = all.filter((e) => (!category || e.category === category) && (!q || e.name.toLowerCase().includes(q) || e.muscleGroups.some((m) => m.toLowerCase().includes(q))))
  const exact = all.some((e) => e.name.toLowerCase() === q)

  const createCustom = async (isCardio: boolean) => {
    const ex: Exercise = { name: query.trim(), category: isCardio ? 'Cardio' : category ?? 'Other', muscleGroups: [], equipment: 'Other', isCardio, isCustom: true }
    try { await db.customExercises.put(ex); onPick(ex) } catch (e) { setError(errorMessage(e)) }
  }

  return (
    <Sheet title="Add Exercise" onClose={onClose} full>
      <div className="stack">
        <input className="input" type="search" placeholder="Search exercises or muscles" value={query} onChange={(e) => setQuery(e.target.value)} aria-label="Search exercises" />
        <div className="chips">
          <button className="chip" aria-pressed={!category} onClick={() => setCategory(null)}>All</button>
          {CATEGORIES.map((c) => <button key={c} className="chip" aria-pressed={category === c} onClick={() => setCategory(c)}>{c}</button>)}
        </div>
        {q && !exact && (
          <div className="grid-2">
            <button className="btn btn-secondary" onClick={() => createCustom(false)}>＋ “{query.trim()}” (strength)</button>
            <button className="btn btn-secondary" onClick={() => createCustom(true)}>＋ “{query.trim()}” (cardio)</button>
          </div>
        )}
        <ErrorBox message={error} />
        <div className="card">
          {results.length === 0 && <div className="empty">No exercises match.</div>}
          {results.map((e) => (
            <button key={e.name} className="list-row" onClick={() => onPick(e)}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14 }}>{e.name}{e.isCustom && <span className="tiny faint"> · custom</span>}</div>
                <div className="tiny faint">{e.isCardio ? 'Cardio' : [e.equipment, ...e.muscleGroups].join(' · ')}</div>
              </div>
            </button>
          ))}
        </div>
      </div>
    </Sheet>
  )
}
