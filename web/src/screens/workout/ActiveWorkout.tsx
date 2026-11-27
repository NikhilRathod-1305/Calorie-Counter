import { useEffect, useState } from 'react'
import { db, newId } from '../../lib/db'
import type { WorkoutSession, WorkoutSet } from '../../lib/types'
import { exerciseGroups, sessionMinutes, sessionVolumeKg } from '../../lib/workout'
import { Sheet } from '../../ui/Sheet'
import { ErrorBox, errorMessage, useToast } from '../../ui/controls'
import { ExercisePicker } from './ExercisePicker'
import { VoiceWorkoutLog } from './VoiceWorkoutLog'

const TICK_MS = 1000

export function ActiveWorkout({ initial, onClose }: { initial: WorkoutSession; onClose: () => void }) {
  const toast = useToast()
  // Local state is the source of truth while open; every change is written through to IndexedDB.
  const [session, setSession] = useState(initial)
  const [picking, setPicking] = useState(false)
  const [voice, setVoice] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [, setTick] = useState(0)

  useEffect(() => {
    const t = window.setInterval(() => setTick((n) => n + 1), TICK_MS)
    return () => window.clearInterval(t)
  }, [])

  const persist = async (next: WorkoutSession) => {
    setSession(next)
    try { await db.workouts.put(next) } catch (e) { setError(errorMessage(e)) }
  }
  const updateSet = (id: string, patch: Partial<WorkoutSet>) => persist({ ...session, sets: session.sets.map((s) => (s.id === id ? { ...s, ...patch } : s)) })
  const removeSet = (id: string) => persist({ ...session, sets: session.sets.filter((s) => s.id !== id) })
  const addSet = (name: string) => {
    const last = [...session.sets].reverse().find((s) => s.exerciseName === name)
    const set: WorkoutSet = { id: newId(), exerciseName: name, isCardio: last?.isCardio ?? false, reps: last?.reps, weightKg: last?.weightKg, minutes: last?.minutes, distanceKm: last?.distanceKm, completed: false }
    void persist({ ...session, sets: [...session.sets, set] })
  }

  const finish = async () => {
    const done = session.sets.filter((s) => s.completed)
    if (done.length === 0 && !confirm('No sets are checked off. Finish anyway?')) return
    await persist({ ...session, sets: done, endedAt: Date.now() })
    toast('Workout saved'); onClose()
  }
  const discard = async () => {
    if (!confirm('Discard this workout?')) return
    try { await db.workouts.delete(session.id); onClose() } catch (e) { setError(errorMessage(e)) }
  }

  const mins = Math.floor(sessionMinutes(session))
  return (
    <Sheet title={session.name} onClose={onClose} full action={<button className="btn btn-primary" style={{ minHeight: 40 }} onClick={finish}>Finish</button>}>
      <div className="stack">
        <div className="row small muted">
          <span>⏱ {Math.floor(mins / 60) ? `${Math.floor(mins / 60)}h ` : ''}{mins % 60}m</span>
          <span>· {session.sets.filter((s) => s.completed).length} sets done</span>
          <span>· {Math.round(sessionVolumeKg(session))} kg volume</span>
        </div>
        <input className="input" value={session.name} aria-label="Workout name" onChange={(e) => void persist({ ...session, name: e.target.value })} />
        {exerciseGroups(session.sets).map((g) => (
          <div className="card" key={g.name}>
            <div className="row" style={{ padding: '12px 14px 4px' }}><span className="bold">{g.name}</span></div>
            <div className="set-row tiny muted"><span>Set</span><span>{g.sets[0].isCardio ? 'Min' : 'kg'}</span><span>{g.sets[0].isCardio ? 'km' : 'Reps'}</span><span /></div>
            {g.sets.map((s, i) => (
              <div className="set-row" key={s.id}>
                <button className="tiny muted" onClick={() => removeSet(s.id)} aria-label={`Delete set ${i + 1}`}>{i + 1} ✕</button>
                <SetInput value={s.isCardio ? s.minutes : s.weightKg} label={s.isCardio ? 'Minutes' : 'Weight in kg'} onChange={(v) => updateSet(s.id, s.isCardio ? { minutes: v } : { weightKg: v })} />
                <SetInput value={s.isCardio ? s.distanceKm : s.reps} label={s.isCardio ? 'Distance in km' : 'Reps'} onChange={(v) => updateSet(s.id, s.isCardio ? { distanceKm: v } : { reps: v })} />
                <button className="check" aria-pressed={s.completed} aria-label={`Mark set ${i + 1} done`} onClick={() => updateSet(s.id, { completed: !s.completed })}>✓</button>
              </div>
            ))}
            <button className="list-row" style={{ justifyContent: 'center', color: 'var(--accent)', fontWeight: 600 }} onClick={() => addSet(g.name)}>＋ Add set</button>
          </div>
        ))}
        {session.sets.length === 0 && <div className="empty">Add an exercise to get started, or log by voice.</div>}
        <div className="grid-2">
          <button className="btn btn-secondary" onClick={() => setPicking(true)}>＋ Exercise</button>
          <button className="btn btn-secondary" onClick={() => setVoice(true)}>🎙️ Voice / Text</button>
        </div>
        <ErrorBox message={error} />
        <button className="btn btn-danger" onClick={discard}>Discard workout</button>
      </div>
      {picking && <ExercisePicker onClose={() => setPicking(false)} onPick={(ex) => {
        setPicking(false)
        void persist({ ...session, sets: [...session.sets, { id: newId(), exerciseName: ex.name, isCardio: ex.isCardio, completed: false }] })
      }} />}
      {voice && <VoiceWorkoutLog active={session} onClose={() => setVoice(false)} onApplied={async (finished) => {
        setVoice(false)
        if (finished) { onClose(); return }
        const fresh = await db.workouts.get(session.id)
        if (fresh) setSession(fresh)
      }} />}
    </Sheet>
  )
}

function SetInput({ value, label, onChange }: { value: number | undefined; label: string; onChange: (v: number | undefined) => void }) {
  return <input className="input" type="number" inputMode="decimal" aria-label={label} value={value ?? ''} onChange={(e) => onChange(e.target.value === '' ? undefined : Math.max(0, Number(e.target.value)))} />
}
