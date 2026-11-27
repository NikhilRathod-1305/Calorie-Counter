import { describe, expect, test } from 'vitest'
import { applyCommands, estimateSessionCalories, exerciseGroups, sessionFromRoutine, sessionVolumeKg, setsFromCommand, setSummary } from './workout'
import type { WorkoutSession } from './types'

const session = (over: Partial<WorkoutSession> = {}): WorkoutSession => ({
  id: 's', name: 'Push', startedAt: 0, endedAt: 60 * 60_000, sets: [
    { id: '1', exerciseName: 'Bench Press', isCardio: false, reps: 10, weightKg: 60, completed: true },
    { id: '2', exerciseName: 'Running', isCardio: true, minutes: 20, distanceKm: 3, completed: true },
    { id: '3', exerciseName: 'Bench Press', isCardio: false, reps: 8, weightKg: 65, completed: false },
  ], ...over,
})

describe('workout helpers', () => {
  test('volume counts only completed strength sets', () => {
    expect(sessionVolumeKg(session())).toBe(600)
  })

  test('groups sets by exercise in first-appearance order', () => {
    const groups = exerciseGroups(session().sets)
    expect(groups.map((g) => g.name)).toEqual(['Bench Press', 'Running'])
    expect(groups[0].sets).toHaveLength(2)
  })

  test('estimates calories: cardio minutes at MET 7, the remaining time at MET 5', () => {
    // 80kg: cardio 20min*7*80/60 = 186.7; strength 40min*5*80/60 = 266.7 → 453
    expect(Math.round(estimateSessionCalories(session(), 80))).toBe(453)
  })

  test('caps strength time so a forgotten open session does not explode', () => {
    const long = session({ endedAt: 10 * 60 * 60_000, sets: [] })
    expect(Math.round(estimateSessionCalories(long, 60))).toBe(Math.round(120 * 5 * 60 / 60))
  })

  test('setsFromCommand expands sets and marks cardio when only a duration is given', () => {
    const sets = setsFromCommand({ action: 'log_set', exerciseName: 'Squat', sets: 3, reps: 8, weightKg: 100 }, () => 'x')
    expect(sets).toHaveLength(3)
    expect(sets[0]).toMatchObject({ exerciseName: 'Squat', reps: 8, weightKg: 100, isCardio: false, completed: true })
    const cardio = setsFromCommand({ action: 'log_set', exerciseName: 'Run', durationMinutes: 30 }, () => 'y')
    expect(cardio).toHaveLength(1)
    expect(cardio[0].isCardio).toBe(true)
  })

  test('setSummary formats strength and cardio sets', () => {
    const [bench, run] = session().sets
    expect(setSummary(bench)).toBe('60 kg × 10 reps')
    expect(setSummary(run)).toBe('20 min · 3.00 km')
  })
})

describe('applyCommands', () => {
  let n = 0
  const id = () => `id${n++}`

  test('starts a named session when none is active and appends sets', () => {
    const { session, finished, added } = applyCommands(null, [
      { action: 'start_workout', workoutName: 'leg day' },
      { action: 'log_set', exerciseName: 'Squat', sets: 2, reps: 5, weightKg: 100 },
    ], id, 1000)
    expect(session.name).toBe('Leg Day')
    expect(session.startedAt).toBe(1000)
    expect(added).toBe(2)
    expect(finished).toBe(false)
    expect(session.endedAt).toBeUndefined()
  })

  test('finish_workout ends the session without mutating the input', () => {
    const active: WorkoutSession = { id: 'a', name: 'Push', startedAt: 0, sets: [] }
    const { session, finished } = applyCommands(active, [{ action: 'finish_workout' }], id, 5000)
    expect(finished).toBe(true)
    expect(session.endedAt).toBe(5000)
    expect(active.endedAt).toBeUndefined()
  })
})

describe('sessionFromRoutine', () => {
  test('creates one incomplete set per target set with targets pre-filled', () => {
    const s = sessionFromRoutine({ id: 'r', name: 'Push Day', createdAt: 0, exercises: [
      { exerciseName: 'Bench Press', isCardio: false, targetSets: 3, targetReps: 8, targetWeightKg: 60 },
      { exerciseName: 'Running', isCardio: true, targetSets: 1, targetMinutes: 10 },
    ] }, 'x', () => 'i', 0)
    expect(s.name).toBe('Push Day')
    expect(s.sets).toHaveLength(4)
    expect(s.sets[0]).toMatchObject({ reps: 8, weightKg: 60, completed: false })
    expect(s.sets[3]).toMatchObject({ isCardio: true, minutes: 10 })
  })
})
