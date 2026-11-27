import { useState } from 'react'
import { db, newId } from '../lib/db'
import { Sheet } from '../ui/Sheet'
import { ErrorBox, NumberField, errorMessage } from '../ui/controls'

const MAX_KCAL = 5000

export function LogExercise({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const [name, setName] = useState('')
  const [calories, setCalories] = useState<number | undefined>()
  const [minutes, setMinutes] = useState<number | undefined>()
  const [error, setError] = useState<string | null>(null)

  const save = async () => {
    if (!name.trim()) return setError('Enter what you did, e.g. “Badminton”.')
    if (!calories || calories <= 0 || calories > MAX_KCAL) return setError(`Calories must be between 1 and ${MAX_KCAL}.`)
    try {
      await db.exercise.add({ id: newId(), timestamp: Date.now(), name: name.trim(), calories, ...(minutes ? { minutes } : {}) })
      onSaved()
    } catch (e) { setError(errorMessage(e)) }
  }

  return (
    <Sheet title="Calories Burned" onClose={onClose}>
      <div className="stack">
        <label className="field"><span className="field-label">Activity</span><input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Badminton" /></label>
        <div className="grid-2">
          <NumberField label="Calories" suffix="kcal" value={calories} onChange={setCalories} />
          <NumberField label="Duration" suffix="min" value={minutes} onChange={setMinutes} />
        </div>
        <ErrorBox message={error} />
        <button className="btn btn-primary btn-block" onClick={save}>Save</button>
      </div>
    </Sheet>
  )
}
