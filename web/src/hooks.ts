import { useLiveQuery } from 'dexie-react-hooks'
import { db, getProfile } from './lib/db'
import { computeGoals, defaultProfile } from './lib/goals'

/** Live profile + derived goals. `loaded` is false until IndexedDB answers. */
export function useProfile() {
  const profile = useLiveQuery(getProfile)
  return { profile: profile ?? defaultProfile, loaded: profile !== undefined, goals: computeGoals(profile ?? defaultProfile) }
}

export function useLatestWeight(fallbackKg: number): number {
  const latest = useLiveQuery(() => db.weights.orderBy('timestamp').last())
  return latest?.kg ?? fallbackKg
}
