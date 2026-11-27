import { zeroNutrition } from './nutrition'
import type { MealEntry, MealType, WaterLog, WeightLog, ExerciseLog } from './types'
import { MEAL_TYPES } from './types'

const HEADER_PREFIX = 'Section,Date,Name,Meal/Type,Calories'

/** Splits one CSV line, honoring double-quoted fields and "" escapes. */
export function splitCsvLine(line: string): string[] {
  const out: string[] = []
  let field = ''
  let inQuotes = false
  for (let i = 0; i < line.length; i++) {
    const ch = line[i]
    if (inQuotes) {
      if (ch === '"' && line[i + 1] === '"') { field += '"'; i++ }
      else if (ch === '"') inQuotes = false
      else field += ch
    } else if (ch === '"') inQuotes = true
    else if (ch === ',') { out.push(field); field = '' }
    else field += ch
  }
  out.push(field)
  return out
}

/** Splits into records, keeping newlines that sit inside quoted fields. */
function splitRecords(text: string): string[] {
  const records: string[] = []
  let current = ''
  let quoteCount = 0
  for (const line of text.replace(/\r\n?/g, '\n').split('\n')) {
    current = current ? `${current}\n${line}` : line
    quoteCount += (line.match(/"/g) ?? []).length
    if (quoteCount % 2 === 0) { if (current.trim()) records.push(current); current = ''; quoteCount = 0 }
  }
  return records
}

function parseDate(s: string): number {
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$/)
  if (!m) throw new Error(`Unrecognized date "${s}"`)
  return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5]).getTime()
}

const n = (s: string) => Number(s) || 0

export interface ImportedData {
  meals: Omit<MealEntry, 'id'>[]
  exercise: Omit<ExerciseLog, 'id'>[]
  weights: Omit<WeightLog, 'id'>[]
  water: Omit<WaterLog, 'id'>[]
}

/** Parses the CSV produced by the iOS app's More → Export Data (CSV). */
export function parseIosExportCsv(text: string): ImportedData {
  const records = splitRecords(text.replace(/^﻿/, ''))
  if (!records[0]?.startsWith(HEADER_PREFIX)) throw new Error("This doesn't look like a Count on Me export (CSV).")
  const result: ImportedData = { meals: [], exercise: [], weights: [], water: [] }

  for (const record of records.slice(1)) {
    const [section, date, name, mealType, cals, protein, carbs, fat, fiber, sugar, sodium, amount] = splitCsvLine(record)
    const timestamp = parseDate(date)
    if (section === 'Food') {
      const meal = (MEAL_TYPES as readonly string[]).includes(mealType) ? (mealType as MealType) : 'Snack'
      result.meals.push({
        timestamp, mealType: meal, name, inputMethod: 'Import',
        items: [{ name, servings: 1, base: { ...zeroNutrition, calories: n(cals), protein: n(protein), carbs: n(carbs), fat: n(fat), fiber: n(fiber), sugar: n(sugar), sodium: n(sodium) } }],
      })
    } else if (section === 'Exercise') {
      const minutes = parseFloat(amount)
      result.exercise.push({ timestamp, name, calories: Math.abs(n(cals)), ...(Number.isFinite(minutes) ? { minutes } : {}) })
    } else if (section === 'Weight') {
      result.weights.push({ timestamp, kg: parseFloat(amount) })
    } else if (section === 'Water') {
      result.water.push({ timestamp, ml: parseInt(amount, 10), drink: 'water' })
    }
  }
  return result
}
