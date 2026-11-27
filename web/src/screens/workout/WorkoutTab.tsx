import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, newId } from '../../lib/db'
import { fmtDay } from '../../lib/dates'
import type { Routine, WorkoutSession } from '../../lib/types'
import { estimateSessionCalories, sessionFromRoutine, sessionMinutes, sessionVolumeKg } from '../../lib/workout'
import { useProfile } from '../../hooks'
import { ErrorBox, errorMessage } from '../../ui/controls'
import { ActiveWorkout } from './ActiveWorkout'
import { RoutineBuilder } from './RoutineBuilder'
import { SessionDetail } from './SessionDetail'
import { VoiceWorkoutLog } from './VoiceWorkoutLog'

const HISTORY_LIMIT = 30

export function WorkoutTab({ openId, onOpen }: { openId: string | null; onOpen: (id: string | null) => void }) {
  const { profile } = useProfile()
  const routines = useLiveQuery(() => db.routines.orderBy('name').toArray()) ?? []
  const sessions = useLiveQuery(() => db.workouts.orderBy('startedAt').reverse().limit(HISTORY_LIMIT + 5).toArray()) ?? []
  const [editing, setEditing] = useState<Routine | 'new' | null>(null)
  const [detail, setDetail] = useState<WorkoutSession | null>(null)
  const [voice, setVoice] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const active = sessions.find((s) => !s.endedAt) ?? null
  const history = sessions.filter((s) => s.endedAt).slice(0, HISTORY_LIMIT)
  const open = sessions.find((s) => s.id === openId && !s.endedAt)

  const start = async (routine: Routine | null) => {
    if (active) { onOpen(active.id); return }
    try {
      const s = sessionFromRoutine(routine, 'Workout', newId, Date.now())
      await db.workouts.add(s)
      onOpen(s.id)
    } catch (e) { setError(errorMessage(e)) }
  }

  return (
    <div className="screen">
      <h1 className="screen-title">Workout</h1>
      <div className="stack">
        {active ? (
          <button className="card card-pad row" style={{ background: 'var(--accent)', color: 'var(--on-accent)' }} onClick={() => onOpen(active.id)}>
            <span style={{ fontSize: 28 }} aria-hidden="true">🏋️</span>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div className="bold">{active.name} in progress</div>
              <div className="small">{Math.floor(sessionMinutes(active))} min · {active.sets.filter((s) => s.completed).length} sets done. Tap to continue</div>
            </div>
          </button>
        ) : (
          <div className="grid-2">
            <button className="btn btn-primary" onClick={() => start(null)}>Start empty workout</button>
            <button className="btn btn-secondary" onClick={() => setVoice(true)}>🎙️ Log by voice</button>
          </div>
        )}
        <ErrorBox message={error} />

        <div className="row"><div className="section-label">Routines</div><span className="spacer" /><button className="chip" onClick={() => setEditing('new')}>＋ New</button></div>
        <div className="card">
          {routines.length === 0 && <div className="empty">No routines yet. Create one to start workouts faster.</div>}
          {routines.map((r) => (
            <div className="list-row" key={r.id}>
              <button style={{ flex: 1, textAlign: 'left' }} onClick={() => setEditing(r)}>
                <div className="bold" style={{ fontSize: 14 }}>{r.name}</div>
                <div className="tiny faint">{r.exercises.map((e) => e.exerciseName).join(', ') || 'No exercises'}</div>
              </button>
              <button className="btn btn-secondary" style={{ minHeight: 36, padding: '0 14px' }} onClick={() => start(r)} disabled={!!active}>Start</button>
            </div>
          ))}
        </div>

        <div className="section-label">History</div>
        <div className="card">
          {history.length === 0 && <div className="empty">Finished workouts show up here.</div>}
          {history.map((s) => (
            <button className="list-row" key={s.id} onClick={() => setDetail(s)}>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14 }}>{s.name}</div>
                <div className="tiny faint">{fmtDay(s.startedAt)} · {Math.round(sessionMinutes(s))} min · {s.sets.length} sets · {Math.round(sessionVolumeKg(s))} kg</div>
              </div>
              <span className="small muted">~{Math.round(estimateSessionCalories(s, profile.weightKg))} kcal</span>
            </button>
          ))}
        </div>
      </div>

      {open && <ActiveWorkout key={open.id} initial={open} onClose={() => onOpen(null)} />}
      {editing && <RoutineBuilder routine={editing === 'new' ? null : editing} onClose={() => setEditing(null)} />}
      {detail && <SessionDetail session={detail} onClose={() => setDetail(null)} />}
      {voice && <VoiceWorkoutLog active={null} onClose={() => setVoice(false)} onApplied={() => setVoice(false)} />}
    </div>
  )
}
