import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../../lib/db'
import type { Exercise } from '../../lib/types'
import starter from '../../data/exercises.json'

export const starterExercises: readonly Exercise[] = starter as Exercise[]

export function useAllExercises(): Exercise[] {
  const custom = useLiveQuery(() => db.customExercises.toArray()) ?? []
  return [...custom, ...starterExercises]
}
