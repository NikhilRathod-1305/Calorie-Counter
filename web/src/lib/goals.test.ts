import { describe, expect, test } from 'vitest'
import { computeGoals, defaultProfile } from './goals'

describe('computeGoals', () => {
  test('matches the iOS Mifflin-St Jeor calculation for a maintaining male', () => {
    // BMR = 10*80 + 6.25*178 - 5*30 + 5 = 1767.5; TDEE = 1767.5*1.55 = 2739.6 → 2740
    const goals = computeGoals({ ...defaultProfile, sex: 'Male', goalType: 'Maintain weight' })
    expect(goals.calorieGoal).toBe(2740)
    expect(goals.proteinG).toBe(206) // 2740*0.30/4 = 205.5 → 206
    expect(goals.carbG).toBe(274)
    expect(goals.fatG).toBe(91)
  })

  test('applies the weekly-rate deficit when losing weight', () => {
    // deficit = 0.5*7700/7 = 550 → 2739.6 - 550 = 2189.6 → 2190
    const goals = computeGoals({ ...defaultProfile, sex: 'Male', goalType: 'Lose weight', weeklyRateKg: 0.5 })
    expect(goals.calorieGoal).toBe(2190)
  })

  test('never goes below the 1200 kcal floor', () => {
    const goals = computeGoals({ ...defaultProfile, sex: 'Female', weightKg: 45, heightCm: 150, age: 70, activityLevel: 'Sedentary', goalType: 'Lose weight', weeklyRateKg: 1 })
    expect(goals.calorieGoal).toBe(1200)
  })
})
