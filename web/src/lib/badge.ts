import type { BadgeMode } from './prefs'
import type { MealType } from './types'

export const GLASS_ML = 250
const MAIN_MEALS: readonly MealType[] = ['Breakfast', 'Lunch', 'Dinner']

export interface BadgeInputs {
  calorieGoal: number
  foodKcal: number
  burnedKcal: number
  waterMl: number
  waterGoalMl: number
  mealsLogged: readonly MealType[]
}

/** The number to show on the app icon for today; 0 means no badge. */
export function badgeCount(mode: BadgeMode, d: BadgeInputs): number {
  switch (mode) {
    // Rounded the same way as the Home ring so the two always agree.
    case 'calories': return Math.max(0, d.calorieGoal - Math.round(d.foodKcal) + Math.round(d.burnedKcal))
    case 'water': return Math.max(0, Math.ceil((d.waterGoalMl - d.waterMl) / GLASS_ML))
    case 'meals': return MAIN_MEALS.filter((m) => !d.mealsLogged.includes(m)).length
    default: return 0
  }
}

type BadgeNavigator = Navigator & { setAppBadge?: (n?: number) => Promise<void>; clearAppBadge?: () => Promise<void> }

export const badgeSupported = (): boolean => typeof navigator !== 'undefined' && 'setAppBadge' in navigator

/** Sets or clears the icon badge. Resolves false when the device can't show badges. */
export async function applyBadge(count: number): Promise<boolean> {
  const nav = navigator as BadgeNavigator
  if (!nav.setAppBadge || !nav.clearAppBadge) return false
  try {
    if (count > 0) await nav.setAppBadge(count)
    else await nav.clearAppBadge()
    return true
  } catch {
    return false // e.g. notification permission not granted on iOS
  }
}
