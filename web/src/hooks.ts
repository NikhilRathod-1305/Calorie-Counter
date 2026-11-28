import { useEffect, useMemo, useState, useSyncExternalStore } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, getProfile } from './lib/db'
import { computeGoals, defaultProfile } from './lib/goals'
import { applyBadge, badgeCount } from './lib/badge'
import { endOfDay, startOfDay } from './lib/dates'
import { entryTotal } from './lib/nutrition'
import { parsePrefs, prefsSnapshot, subscribePrefs, type BadgeMode, type Prefs } from './lib/prefs'
import { hydrationMl } from './lib/types'
import { dayBurnedCalories } from './lib/workout'

/** Live profile + derived goals. `loaded` is false until IndexedDB answers. */
export function useProfile() {
  const profile = useLiveQuery(getProfile)
  return { profile: profile ?? defaultProfile, loaded: profile !== undefined, goals: computeGoals(profile ?? defaultProfile) }
}

export function useLatestWeight(fallbackKg: number): number {
  const latest = useLiveQuery(() => db.weights.orderBy('timestamp').last())
  return latest?.kg ?? fallbackKg
}

/** Live device preferences (badge, launch screen, + long-press). */
export function usePrefs(): Prefs {
  const raw = useSyncExternalStore(subscribePrefs, prefsSnapshot)
  return useMemo(() => parsePrefs(raw || null), [raw])
}

/** Keeps the app-icon badge in sync with today's numbers while the app is open. */
export function useAppBadge(mode: BadgeMode): void {
  const { profile, goals } = useProfile()
  const [today, setToday] = useState(() => startOfDay(Date.now()))
  useEffect(() => {
    const sync = () => setToday(startOfDay(Date.now()))
    document.addEventListener('visibilitychange', sync)
    const t = window.setInterval(sync, 60_000)
    return () => { document.removeEventListener('visibilitychange', sync); window.clearInterval(t) }
  }, [])
  const range = [today, endOfDay(today), true, true] as const
  const meals = useLiveQuery(() => db.meals.where('timestamp').between(...range).toArray(), [today])
  const water = useLiveQuery(() => db.water.where('timestamp').between(...range).toArray(), [today])
  const exercise = useLiveQuery(() => db.exercise.where('timestamp').between(...range).toArray(), [today])
  const workouts = useLiveQuery(() => db.workouts.where('startedAt').between(...range).toArray(), [today])

  const ready = meals && water && exercise && workouts
  const count = !ready ? null : badgeCount(mode, {
    calorieGoal: goals.calorieGoal,
    foodKcal: meals.reduce((s, m) => s + entryTotal(m).calories, 0),
    burnedKcal: dayBurnedCalories(exercise, workouts, profile.weightKg),
    waterMl: water.reduce((s, w) => s + hydrationMl(w), 0),
    waterGoalMl: profile.waterGoalMl,
    mealsLogged: meals.map((m) => m.mealType),
  })
  useEffect(() => { if (count !== null) void applyBadge(count) }, [count])
}
