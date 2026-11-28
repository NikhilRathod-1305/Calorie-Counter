import { describe, expect, test } from 'vitest'
import { badgeCount, type BadgeInputs } from './badge'

const base: BadgeInputs = { calorieGoal: 2000, foodKcal: 800, burnedKcal: 150, waterMl: 750, waterGoalMl: 2000, mealsLogged: ['Breakfast'] }

describe('badgeCount', () => {
  test('is zero when the badge is off', () => {
    expect(badgeCount('off', base)).toBe(0)
  })

  test('shows calories left including exercise', () => {
    expect(badgeCount('calories', base)).toBe(1350)
  })

  test('rounds food like the Home ring does', () => {
    expect(badgeCount('calories', { ...base, foodKcal: 491.6, burnedKcal: 0 })).toBe(2000 - 492)
  })

  test('never goes negative when over the calorie goal', () => {
    expect(badgeCount('calories', { ...base, foodKcal: 3000 })).toBe(0)
  })

  test('rounds remaining water up to whole 250 ml glasses', () => {
    expect(badgeCount('water', base)).toBe(5)
    expect(badgeCount('water', { ...base, waterMl: 1900 })).toBe(1)
    expect(badgeCount('water', { ...base, waterMl: 2500 })).toBe(0)
  })

  test('counts breakfast, lunch and dinner not yet logged (snacks ignored)', () => {
    expect(badgeCount('meals', base)).toBe(2)
    expect(badgeCount('meals', { ...base, mealsLogged: ['Snack'] })).toBe(3)
    expect(badgeCount('meals', { ...base, mealsLogged: ['Breakfast', 'Lunch', 'Dinner'] })).toBe(0)
  })
})
