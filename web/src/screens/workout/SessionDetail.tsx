import { useState } from 'react'
import { db } from '../../lib/db'
import { fmtDay, fmtTime } from '../../lib/dates'
import type { WorkoutSession } from '../../lib/types'
import { estimateSessionCalories, exerciseGroups, sessionMinutes, sessionVolumeKg, setSummary } from '../../lib/workout'
import { useProfile } from '../../hooks'
import { Sheet } from '../../ui/Sheet'
import { ErrorBox, errorMessage, useToast } from '../../ui/controls'

export function SessionDetail({ session, onClose }: { session: WorkoutSession; onClose: () => void }) {
  const { profile } = useProfile()
  const toast = useToast()
  const [error, setError] = useState<string | null>(null)

  const remove = async () => {
    if (!confirm('Delete this workout?')) return
    try { await db.workouts.delete(session.id); toast('Deleted'); onClose() } catch (e) { setError(errorMessage(e)) }
  }

  return (
    <Sheet title={session.name} onClose={onClose}>
      <div className="stack">
        <div className="small muted">{fmtDay(session.startedAt)} · {fmtTime(session.startedAt)}</div>
        <div className="card card-pad grid-3 center">
          <div><div className="num bold">{Math.round(sessionMinutes(session))}</div><div className="tiny muted">minutes</div></div>
          <div><div className="num bold">{Math.round(sessionVolumeKg(session))}</div><div className="tiny muted">kg volume</div></div>
          <div><div className="num bold">~{Math.round(estimateSessionCalories(session, profile.weightKg))}</div><div className="tiny muted">kcal</div></div>
        </div>
        {exerciseGroups(session.sets).map((g) => (
          <div className="card" key={g.name}>
            <div className="list-row bold">{g.name}</div>
            {g.sets.map((s, i) => <div className="list-row small" key={s.id}><span className="muted">Set {i + 1}</span><span className="spacer" />{setSummary(s)}</div>)}
          </div>
        ))}
        <div className="tiny faint">Calories are a rough estimate from workout time and your body weight.</div>
        <ErrorBox message={error} />
        <button className="btn btn-danger" onClick={remove}>Delete workout</button>
      </div>
    </Sheet>
  )
}
