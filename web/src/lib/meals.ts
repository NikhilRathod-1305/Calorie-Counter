import { db, newId } from './db'
import type { EntryItem } from './nutrition'
import type { FoodItem, InputMethod, MealEntry, MealType } from './types'
import foods from '../data/foods.json'

export const libraryFoods: readonly FoodItem[] = (foods as Omit<FoodItem, 'id' | 'isCustom'>[]).map((f, i) => ({ ...f, id: `lib-${i}`, isCustom: false }))

export function foodToItem(food: FoodItem, servings = 1): EntryItem {
  const { calories, protein, carbs, fat, fiber, sugar, sodium } = food
  return { name: food.name, base: { calories, protein, carbs, fat, fiber, sugar, sodium }, servings, servingLabel: `${food.servingSize}${food.servingUnit}` }
}

export function groupName(items: readonly EntryItem[]): string {
  if (items.length === 1) return items[0].name
  const [a, b] = items
  return items.length === 2 ? `${a.name} & ${b.name}` : `${a.name}, ${b.name} +${items.length - 2}`
}

export async function addMealEntry(items: readonly EntryItem[], mealType: MealType, timestamp: number, inputMethod: InputMethod): Promise<void> {
  if (items.length === 0) throw new Error('Nothing to save.')
  const entry: MealEntry = { id: newId(), timestamp, mealType, inputMethod, name: groupName(items), items: [...items] }
  await db.meals.add(entry)
}

export function searchFoods(all: readonly FoodItem[], query: string, category: string | null): FoodItem[] {
  const q = query.trim().toLowerCase()
  return all.filter((f) => (!category || f.category === category) && (!q || f.name.toLowerCase().includes(q) || f.brand?.toLowerCase().includes(q)))
}
