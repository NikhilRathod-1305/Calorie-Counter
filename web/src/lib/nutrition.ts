export interface Nutrition {
  calories: number
  protein: number
  carbs: number
  fat: number
  fiber: number
  sugar: number
  sodium: number
}

export const zeroNutrition: Nutrition = Object.freeze({
  calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0,
})

const KEYS = Object.keys(zeroNutrition) as (keyof Nutrition)[]

export function scale(n: Nutrition, factor: number): Nutrition {
  return Object.fromEntries(KEYS.map((k) => [k, n[k] * factor])) as unknown as Nutrition
}

export function add(a: Nutrition, b: Nutrition): Nutrition {
  return Object.fromEntries(KEYS.map((k) => [k, a[k] + b[k]])) as unknown as Nutrition
}

export function sumNutrition(list: readonly Nutrition[]): Nutrition {
  return list.reduce(add, { ...zeroNutrition })
}

/** One food inside a logged entry: the nutrition of a single serving/portion, times how many. */
export interface EntryItem {
  name: string
  base: Nutrition
  servings: number
  /** e.g. "150g" for a library food; absent for AI-estimated portions. */
  servingLabel?: string
}

export function itemTotal(item: EntryItem): Nutrition {
  return scale(item.base, item.servings)
}

export function entryTotal(entry: { items: readonly EntryItem[] }): Nutrition {
  return sumNutrition(entry.items.map(itemTotal))
}

export function formatServings(servings: number): string {
  return Number.isInteger(servings) ? String(servings) : servings.toFixed(1)
}
