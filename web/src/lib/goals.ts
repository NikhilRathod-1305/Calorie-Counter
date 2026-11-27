export type Sex = 'Female' | 'Male' | 'Other'
export type ActivityLevel = 'Sedentary' | 'Light' | 'Moderate' | 'Active'
export type GoalType = 'Lose weight' | 'Maintain weight' | 'Gain weight'
export type MacroPreset = 'Balanced' | 'High-protein' | 'Low-carb'
export type Appearance = 'System' | 'Light' | 'Dark'

export interface Profile {
  heightCm: number
  age: number
  weightKg: number
  targetWeightKg: number
  activityLevel: ActivityLevel
  macroPreset: MacroPreset
  goalType: GoalType
  sex: Sex
  weeklyRateKg: number
  waterGoalMl: number
  weeklyExerciseGoalMinutes: number
  appearance: Appearance
  hasCompletedOnboarding: boolean
}

export const defaultProfile: Profile = Object.freeze({
  heightCm: 178,
  age: 30,
  weightKg: 80,
  targetWeightKg: 75,
  activityLevel: 'Moderate',
  macroPreset: 'Balanced',
  goalType: 'Maintain weight',
  sex: 'Other',
  weeklyRateKg: 0.5,
  waterGoalMl: 2000,
  weeklyExerciseGoalMinutes: 150,
  appearance: 'System',
  hasCompletedOnboarding: false,
})

export const ACTIVITY_LEVELS: readonly ActivityLevel[] = ['Sedentary', 'Light', 'Moderate', 'Active']
export const GOAL_TYPES: readonly GoalType[] = ['Lose weight', 'Maintain weight', 'Gain weight']
export const MACRO_PRESETS: readonly MacroPreset[] = ['Balanced', 'High-protein', 'Low-carb']
export const SEXES: readonly Sex[] = ['Female', 'Male', 'Other']

const ACTIVITY_MULTIPLIER: Record<ActivityLevel, number> = {
  Sedentary: 1.2, Light: 1.375, Moderate: 1.55, Active: 1.725,
}
const MACRO_SPLIT: Record<MacroPreset, { protein: number; carb: number; fat: number }> = {
  Balanced: { protein: 0.3, carb: 0.4, fat: 0.3 },
  'High-protein': { protein: 0.4, carb: 0.3, fat: 0.3 },
  'Low-carb': { protein: 0.35, carb: 0.2, fat: 0.45 },
}
const SEX_CONSTANT: Record<Sex, number> = { Male: 5, Female: -161, Other: -78 }
const KCAL_PER_KG_BODY_FAT = 7700
const MINIMUM_CALORIE_GOAL = 1200

export const FIBER_TARGET_G = 28
export const SUGAR_LIMIT_G = 50
export const SODIUM_LIMIT_MG = 2300

export interface DailyGoals {
  calorieGoal: number
  proteinG: number
  carbG: number
  fatG: number
}

/** Mifflin-St Jeor BMR × activity multiplier ± weekly-rate adjustment — same as the iOS NutritionGoalCalculator. */
export function computeGoals(p: Profile): DailyGoals {
  const bmr = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age + SEX_CONSTANT[p.sex]
  const tdee = bmr * ACTIVITY_MULTIPLIER[p.activityLevel]
  const dailyDelta = (p.weeklyRateKg * KCAL_PER_KG_BODY_FAT) / 7
  const adjustment = p.goalType === 'Lose weight' ? -dailyDelta : p.goalType === 'Gain weight' ? dailyDelta : 0
  const rawGoal = Math.max(MINIMUM_CALORIE_GOAL, tdee + adjustment)
  const calorieGoal = Math.round(rawGoal / 10) * 10
  const split = MACRO_SPLIT[p.macroPreset]
  return {
    calorieGoal,
    proteinG: Math.round((calorieGoal * split.protein) / 4),
    carbG: Math.round((calorieGoal * split.carb) / 4),
    fatG: Math.round((calorieGoal * split.fat) / 9),
  }
}

export function bmi(p: Pick<Profile, 'heightCm'>, weightKg: number): number {
  const m = p.heightCm / 100
  return m > 0 ? weightKg / (m * m) : 0
}

export function bmiCategory(value: number): string {
  if (value < 18.5) return 'Underweight'
  if (value < 25) return 'Healthy'
  if (value < 30) return 'Overweight'
  return 'Obese'
}
