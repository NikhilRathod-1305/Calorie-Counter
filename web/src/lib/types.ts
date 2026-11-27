import type { EntryItem } from './nutrition'

export const MEAL_TYPES = ['Breakfast', 'Lunch', 'Dinner', 'Snack'] as const
export type MealType = (typeof MEAL_TYPES)[number]
export const MEAL_EMOJI: Record<MealType, string> = { Breakfast: '🥞', Lunch: '🥗', Dinner: '🍝', Snack: '🥑' }

export function currentMealType(now = new Date()): MealType {
  const h = now.getHours()
  if (h >= 5 && h < 11) return 'Breakfast'
  if (h >= 11 && h < 15) return 'Lunch'
  if (h >= 15 && h < 18) return 'Snack'
  return 'Dinner'
}

export type InputMethod = 'Text' | 'Voice' | 'Photo' | 'Search' | 'Manual' | 'Barcode' | 'Import'

export interface MealEntry {
  id: string
  timestamp: number
  mealType: MealType
  /** Group name for multi-item scans, otherwise the food's name. */
  name: string
  inputMethod: InputMethod
  items: EntryItem[]
}

export interface FoodItem {
  id: string
  name: string
  brand: string | null
  serving: string
  servingSize: number
  servingUnit: string
  calories: number
  protein: number
  carbs: number
  fat: number
  fiber: number
  sugar: number
  sodium: number
  category: string
  emoji: string
  isCustom: boolean
}

export interface WaterLog { id: string; timestamp: number; ml: number; drink: DrinkType }
export interface WeightLog { id: string; timestamp: number; kg: number }
export interface ExerciseLog { id: string; timestamp: number; name: string; calories: number; minutes?: number }

export interface Exercise {
  name: string
  category: string
  muscleGroups: string[]
  equipment: string
  isCardio: boolean
  isCustom?: boolean
}

export interface WorkoutSet {
  id: string
  exerciseName: string
  isCardio: boolean
  reps?: number
  weightKg?: number
  minutes?: number
  distanceKm?: number
  completed: boolean
}

export interface WorkoutSession {
  id: string
  name: string
  startedAt: number
  endedAt?: number
  routineName?: string
  sets: WorkoutSet[]
}

export interface RoutineExercise {
  exerciseName: string
  isCardio: boolean
  targetSets: number
  targetReps?: number
  targetWeightKg?: number
  targetMinutes?: number
}

export interface Routine { id: string; name: string; exercises: RoutineExercise[]; createdAt: number }

export const DRINKS = {
  water: { label: 'Water', emoji: '💧', factor: 1 },
  coffee: { label: 'Coffee', emoji: '☕', factor: 0.8 },
  tea: { label: 'Tea', emoji: '🍵', factor: 0.9 },
  juice: { label: 'Juice', emoji: '🧃', factor: 0.9 },
  sportDrink: { label: 'Sport Drink', emoji: '⚡', factor: 1 },
  coconutWater: { label: 'Coconut Water', emoji: '🥥', factor: 1 },
  smoothie: { label: 'Smoothie', emoji: '🥤', factor: 0.9 },
  chocolateMilk: { label: 'Chocolate', emoji: '🍫', factor: 0.9 },
  soda: { label: 'Carbonated', emoji: '🫧', factor: 0.9 },
  wine: { label: 'Wine', emoji: '🍷', factor: 0.5 },
  beer: { label: 'Beer', emoji: '🍺', factor: 0.5 },
  liquor: { label: 'Liquor', emoji: '🥃', factor: 0.5 },
} as const
export type DrinkType = keyof typeof DRINKS

export const CUP_SIZES = [100, 150, 200, 250, 300, 350, 400, 500, 600] as const

export const hydrationMl = (w: Pick<WaterLog, 'ml' | 'drink'>) => w.ml * (DRINKS[w.drink]?.factor ?? 1)
