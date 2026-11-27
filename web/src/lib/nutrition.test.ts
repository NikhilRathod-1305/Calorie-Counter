import { describe, expect, test } from 'vitest'
import { entryTotal, sumNutrition, scale, zeroNutrition, type Nutrition } from './nutrition'

const n = (calories: number, protein = 0): Nutrition => ({ ...zeroNutrition, calories, protein })

describe('nutrition math', () => {
  test('scale multiplies every field', () => {
    expect(scale(n(100, 10), 1.5)).toEqual({ ...zeroNutrition, calories: 150, protein: 15 })
  })

  test('sumNutrition adds a list and returns zero for empty input', () => {
    expect(sumNutrition([])).toEqual(zeroNutrition)
    expect(sumNutrition([n(100), n(50, 5)])).toEqual({ ...zeroNutrition, calories: 150, protein: 5 })
  })

  test('entryTotal sums every item scaled by its servings', () => {
    const total = entryTotal({ items: [{ name: 'eggs', base: n(140, 12), servings: 2 }, { name: 'toast', base: n(80), servings: 1 }] })
    expect(total.calories).toBe(360)
    expect(total.protein).toBe(24)
  })

  test('scale does not mutate its input', () => {
    const base = n(100)
    scale(base, 2)
    expect(base.calories).toBe(100)
  })
})
