import type { ParsedWorkoutCommand } from './gemini'
import type { Routine, WorkoutSession, WorkoutSet } from './types'

const CARDIO_MET = 7
const STRENGTH_MET = 5
const MAX_STRENGTH_MINUTES = 120

export function sessionMinutes(s: Pick<WorkoutSession, 'startedAt' | 'endedAt'>, now = Date.now()): number {
  return Math.max(0, ((s.endedAt ?? now) - s.startedAt) / 60_000)
}

export function sessionVolumeKg(s: WorkoutSession): number {
  return s.sets.reduce((sum, set) => sum + (set.completed && !set.isCardio ? (set.reps ?? 0) * (set.weightKg ?? 0) : 0), 0)
}

/** Rough MET-based burn: logged cardio minutes at MET 7, the rest of the session at MET 5. */
export function estimateSessionCalories(s: WorkoutSession, bodyKg: number): number {
  const cardioMinutes = s.sets.reduce((sum, set) => sum + (set.completed && set.isCardio ? set.minutes ?? 0 : 0), 0)
  const strengthMinutes = Math.min(MAX_STRENGTH_MINUTES, Math.max(0, sessionMinutes(s) - cardioMinutes))
  return (cardioMinutes * CARDIO_MET * bodyKg) / 60 + (strengthMinutes * STRENGTH_MET * bodyKg) / 60
}

export function exerciseGroups(sets: readonly WorkoutSet[]): { name: string; sets: WorkoutSet[] }[] {
  const groups = new Map<string, WorkoutSet[]>()
  for (const set of sets) groups.set(set.exerciseName, [...(groups.get(set.exerciseName) ?? []), set])
  return [...groups].map(([name, s]) => ({ name, sets: s }))
}

export function setSummary(set: WorkoutSet): string {
  if (set.isCardio) {
    return [set.minutes != null && `${Math.round(set.minutes)} min`, set.distanceKm != null && `${set.distanceKm.toFixed(2)} km`]
      .filter(Boolean).join(' · ') || 'Cardio'
  }
  return [set.weightKg != null && `${set.weightKg} kg`, set.reps != null && `${set.reps} reps`].filter(Boolean).join(' × ') || 'Set'
}

export function setsFromCommand(cmd: ParsedWorkoutCommand, makeId: () => string): WorkoutSet[] {
  if (cmd.action !== 'log_set' || !cmd.exerciseName) return []
  const isCardio = cmd.reps == null && (cmd.durationMinutes != null || cmd.distanceKm != null)
  const count = isCardio ? 1 : Math.max(1, Math.min(20, cmd.sets ?? 1))
  return Array.from({ length: count }, () => ({
    id: makeId(),
    exerciseName: cmd.exerciseName!,
    isCardio,
    ...(isCardio
      ? { minutes: cmd.durationMinutes, distanceKm: cmd.distanceKm }
      : { reps: cmd.reps, weightKg: cmd.weightKg }),
    completed: true,
  }))
}

export function sessionFromRoutine(routine: Routine | null, name: string, makeId: () => string, now: number): WorkoutSession {
  const sets: WorkoutSet[] = (routine?.exercises ?? []).flatMap((ex) =>
    Array.from({ length: ex.isCardio ? 1 : Math.max(1, ex.targetSets) }, () => ({
      id: makeId(), exerciseName: ex.exerciseName, isCardio: ex.isCardio, completed: false,
      ...(ex.isCardio ? { minutes: ex.targetMinutes } : { reps: ex.targetReps, weightKg: ex.targetWeightKg }),
    })))
  return { id: makeId(), name: routine?.name ?? name, startedAt: now, sets, ...(routine ? { routineName: routine.name } : {}) }
}

/**
 * Applies parsed voice/text commands to the active session (or starts one).
 * Returns the resulting session and whether a finish command was included.
 */
export function applyCommands(active: WorkoutSession | null, cmds: readonly ParsedWorkoutCommand[], makeId: () => string, now: number): { session: WorkoutSession; finished: boolean; added: number } {
  let session = active ?? { id: makeId(), name: 'Workout', startedAt: now, sets: [] }
  let finished = false
  let added = 0
  for (const cmd of cmds) {
    if (cmd.action === 'start_workout' && cmd.workoutName && session.sets.length === 0) {
      session = { ...session, name: cmd.workoutName.replace(/\b\w/g, (c) => c.toUpperCase()) }
    } else if (cmd.action === 'log_set') {
      const sets = setsFromCommand(cmd, makeId)
      added += sets.length
      session = { ...session, sets: [...session.sets, ...sets] }
    } else if (cmd.action === 'finish_workout') {
      finished = true
    }
  }
  return { session: finished ? { ...session, endedAt: now } : session, finished, added }
}
