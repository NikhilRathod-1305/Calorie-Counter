import { describe, expect, test } from 'vitest'
import { parseIosExportCsv, splitCsvLine } from './csvImport'

const csv = [
  'Section,Date,Name,Meal/Type,Calories,Protein(g),Carbs(g),Fat(g),Fiber(g),Sugar(g),Sodium(mg),Amount',
  'Food,2026-11-20 08:15,"Eggs, scrambled",Breakfast,143,12.6,1.0,9.5,0.0,0.4,140,',
  'Exercise,2026-11-20 18:00,Running,,-300,,,,,,,30 min',
  'Weight,2026-11-21 07:00,,,,,,,,,,79.4 kg',
  'Water,2026-11-21 09:00,,,,,,,,,,250 ml',
].join('\n')

describe('splitCsvLine', () => {
  test('handles quoted fields with commas and escaped quotes', () => {
    expect(splitCsvLine('a,"b, c","say ""hi""",')).toEqual(['a', 'b, c', 'say "hi"', ''])
  })
})

describe('parseIosExportCsv', () => {
  test('parses every section of the iOS app export', () => {
    const result = parseIosExportCsv(csv)
    expect(result.meals).toHaveLength(1)
    expect(result.meals[0].name).toBe('Eggs, scrambled')
    expect(result.meals[0].mealType).toBe('Breakfast')
    expect(result.meals[0].items[0].base.calories).toBe(143)
    expect(new Date(result.meals[0].timestamp).getHours()).toBe(8)
    expect(result.exercise[0]).toMatchObject({ name: 'Running', calories: 300, minutes: 30 })
    expect(result.weights[0].kg).toBe(79.4)
    expect(result.water[0].ml).toBe(250)
  })

  test('rejects a file that is not an export', () => {
    expect(() => parseIosExportCsv('hello,world')).toThrow(/Count on Me export/)
  })
})
