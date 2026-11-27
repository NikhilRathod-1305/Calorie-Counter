import Dexie, { type EntityTable } from 'dexie'
import { defaultProfile, type Profile } from './goals'
import type { ExerciseLog, FoodItem, MealEntry, Routine, WaterLog, WeightLog, WorkoutSession, Exercise } from './types'
import starterRoutines from '../data/routines.json'

interface KV { key: string; value: unknown }

export class AppDB extends Dexie {
  meals!: EntityTable<MealEntry, 'id'>
  customFoods!: EntityTable<FoodItem, 'id'>
  water!: EntityTable<WaterLog, 'id'>
  weights!: EntityTable<WeightLog, 'id'>
  exercise!: EntityTable<ExerciseLog, 'id'>
  workouts!: EntityTable<WorkoutSession, 'id'>
  routines!: EntityTable<Routine, 'id'>
  customExercises!: EntityTable<Exercise, 'name'>
  kv!: EntityTable<KV, 'key'>

  constructor(name = 'count-on-me') {
    super(name)
    this.version(1).stores({
      meals: 'id, timestamp',
      customFoods: 'id, name',
      water: 'id, timestamp',
      weights: 'id, timestamp',
      exercise: 'id, timestamp',
      workouts: 'id, startedAt, endedAt',
      routines: 'id, name',
      customExercises: 'name',
      kv: 'key',
    })
    this.on('populate', (tx) => {
      const now = Date.now()
      void tx.table('routines').bulkAdd((starterRoutines as Omit<Routine, 'id' | 'createdAt'>[]).map((r, i) => ({ ...r, id: newId(), createdAt: now + i })))
    })
  }
}

export const db = new AppDB()

export const newId = (): string => crypto.randomUUID()

export async function getProfile(): Promise<Profile> {
  const row = await db.kv.get('profile')
  return { ...defaultProfile, ...(row?.value as Partial<Profile> | undefined) }
}

export async function saveProfile(profile: Profile): Promise<void> {
  await db.kv.put({ key: 'profile', value: profile })
}

export async function exportAll(): Promise<string> {
  const [meals, customFoods, water, weights, exercise, workouts, routines, customExercises, profile] = await Promise.all([
    db.meals.toArray(), db.customFoods.toArray(), db.water.toArray(), db.weights.toArray(), db.exercise.toArray(),
    db.workouts.toArray(), db.routines.toArray(), db.customExercises.toArray(), getProfile(),
  ])
  return JSON.stringify({ app: 'count-on-me-web', version: 1, exportedAt: new Date().toISOString(), profile, meals, customFoods, water, weights, exercise, workouts, routines, customExercises })
}

const BACKUP_TABLES = ['meals', 'customFoods', 'water', 'weights', 'exercise', 'workouts', 'routines', 'customExercises'] as const

/** Restores a JSON backup made by exportAll. Merges by id (existing rows with the same id are replaced). */
export async function importBackup(json: string): Promise<number> {
  let data: Record<string, unknown>
  try { data = JSON.parse(json) } catch { throw new Error("That file isn't valid JSON.") }
  if (data?.app !== 'count-on-me-web') throw new Error("This isn't a Count on Me web backup.")
  let count = 0
  await db.transaction('rw', [...BACKUP_TABLES.map((t) => db.table(t)), db.kv], async () => {
    for (const t of BACKUP_TABLES) {
      const rows = data[t]
      if (Array.isArray(rows)) { await db.table(t).bulkPut(rows); count += rows.length }
    }
    if (data.profile && typeof data.profile === 'object') await saveProfile({ ...defaultProfile, ...(data.profile as Partial<Profile>) })
  })
  return count
}
