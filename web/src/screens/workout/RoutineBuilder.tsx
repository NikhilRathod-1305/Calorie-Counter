import { useState } from 'react'
import { db, newId } from '../../lib/db'
import type { Routine, RoutineExercise } from '../../lib/types'
import { Sheet } from '../../ui/Sheet'
import { ErrorBox, errorMessage, useToast } from '../../ui/controls'
import { ExercisePicker } from './ExercisePicker'

const DEFAULT_SETS = 3
const DEFAULT_REPS = 10
const DEFAULT_CARDIO_MIN = 20

export function RoutineBuilder({ routine, onClose }: { routine: Routine | null; onClose: () => void }) {
  const toast = useToast()
  const [name, setName] = useState(routine?.name ?? '')
  const [exercises, setExercises] = useState<RoutineExercise[]>(routine?.exercises ?? [])
  const [picking, setPicking] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const update = (i: number, patch: Partial<RoutineExercise>) => setExercises((xs) => xs.map((x, j) => (j === i ? { ...x, ...patch } : x)))
  const move = (i: number, d: -1 | 1) => setExercises((xs) => {
    const j = i + d
    if (j < 0 || j >= xs.length) return xs
    const copy = [...xs];
    [copy[i], copy[j]] = [copy[j], copy[i]]
    return copy
  })

  const save = async () => {
    if (!name.trim()) return setError('Give the routine a name.')
    try {
      await db.routines.put({ id: routine?.id ?? newId(), createdAt: routine?.createdAt ?? Date.now(), name: name.trim(), exercises })
      toast('Routine saved'); onClose()
    } catch (e) { setError(errorMessage(e)) }
  }
  const remove = async () => {
    if (!routine || !confirm(`Delete “${routine.name}”?`)) return
    try { await db.routines.delete(routine.id); onClose() } catch (e) { setError(errorMessage(e)) }
  }

  const num = (v: string) => (v === '' ? undefined : Math.max(0, Number(v)))

  return (
    <Sheet title={routine ? 'Edit Routine' : 'New Routine'} onClose={onClose} full>
      <div className="stack">
        <label className="field"><span className="field-label">Name</span><input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Upper Body" /></label>
        <div className="card">
          {exercises.length === 0 && <div className="empty">Add exercises to this routine.</div>}
          {exercises.map((ex, i) => (
            <div className="list-row" key={`${ex.exerciseName}-${i}`} style={{ flexWrap: 'wrap' }}>
              <div style={{ flex: '1 1 100%' }} className="row">
                <span className="bold" style={{ fontSize: 14, flex: 1 }}>{ex.exerciseName}</span>
                <button className="icon-btn" style={{ width: 32, height: 32 }} aria-label="Move up" onClick={() => move(i, -1)}>↑</button>
                <button className="icon-btn" style={{ width: 32, height: 32 }} aria-label="Move down" onClick={() => move(i, 1)}>↓</button>
                <button className="swipe-del" onClick={() => setExercises((xs) => xs.filter((_, j) => j !== i))}>Remove</button>
              </div>
              {ex.isCardio ? (
                <div className="grid-2" style={{ flex: 1 }}>
                  <input className="input" type="number" inputMode="decimal" aria-label="Minutes" placeholder="Minutes" value={ex.targetMinutes ?? ''} onChange={(e) => update(i, { targetMinutes: num(e.target.value) })} />
                </div>
              ) : (
                <div className="grid-3" style={{ flex: 1 }}>
                  <input className="input" type="number" inputMode="numeric" aria-label="Sets" placeholder="Sets" value={ex.targetSets} onChange={(e) => update(i, { targetSets: Math.max(1, Math.min(20, Number(e.target.value) || 1)) })} />
                  <input className="input" type="number" inputMode="numeric" aria-label="Reps" placeholder="Reps" value={ex.targetReps ?? ''} onChange={(e) => update(i, { targetReps: num(e.target.value) })} />
                  <input className="input" type="number" inputMode="decimal" aria-label="Weight kg" placeholder="kg" value={ex.targetWeightKg ?? ''} onChange={(e) => update(i, { targetWeightKg: num(e.target.value) })} />
                </div>
              )}
            </div>
          ))}
        </div>
        <button className="btn btn-secondary" onClick={() => setPicking(true)}>＋ Add exercise</button>
        <ErrorBox message={error} />
        <button className="btn btn-primary btn-block" onClick={save}>Save Routine</button>
        {routine && <button className="btn btn-danger" onClick={remove}>Delete routine</button>}
      </div>
      {picking && <ExercisePicker onClose={() => setPicking(false)} onPick={(e) => {
        setPicking(false)
        setExercises((xs) => [...xs, e.isCardio
          ? { exerciseName: e.name, isCardio: true, targetSets: 1, targetMinutes: DEFAULT_CARDIO_MIN }
          : { exerciseName: e.name, isCardio: false, targetSets: DEFAULT_SETS, targetReps: DEFAULT_REPS }])
      }} />}
    </Sheet>
  )
}
