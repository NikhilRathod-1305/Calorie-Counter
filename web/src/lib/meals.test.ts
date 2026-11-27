import { describe, expect, test } from 'vitest'
import { groupName, libraryFoods, searchFoods, foodToItem } from './meals'
import { zeroNutrition } from './nutrition'

const item = (name: string) => ({ name, base: zeroNutrition, servings: 1 })

describe('meals helpers', () => {
  test('groupName summarises multi-item entries', () => {
    expect(groupName([item('Eggs')])).toBe('Eggs')
    expect(groupName([item('Eggs'), item('Toast')])).toBe('Eggs & Toast')
    expect(groupName([item('Eggs'), item('Toast'), item('Juice'), item('Jam')])).toBe('Eggs, Toast +2')
  })

  test('searchFoods matches case-insensitively and filters by category', () => {
    expect(searchFoods(libraryFoods, 'biryani', null).map((f) => f.name)).toContain('Chicken Biryani')
    expect(searchFoods(libraryFoods, '', 'Fruits').every((f) => f.category === 'Fruits')).toBe(true)
  })

  test('foodToItem carries the serving label and per-serving nutrition', () => {
    const banana = libraryFoods.find((f) => f.name === 'Banana')!
    expect(foodToItem(banana, 2)).toMatchObject({ name: 'Banana', servings: 2, servingLabel: '118g', base: { calories: 105 } })
  })
})
