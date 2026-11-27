import { describe, expect, test, vi } from 'vitest'
import { callGemini, GeminiError, parseFoodItems, parseWorkoutCommands, MODEL_FALLBACKS } from './gemini'

const fnResponse = (name: string, args: unknown) => ({
  candidates: [{ content: { parts: [{ functionCall: { name, args } }] } }],
})

describe('parseFoodItems', () => {
  test('maps every item to nutrition fields', () => {
    const items = parseFoodItems(fnResponse('log_food', { items: [
      { name: 'Eggs', calories: 140, protein_g: 12, carbs_g: 1, fat_g: 10, fiber_g: 0, sugar_g: 0, sodium_mg: 140 },
      { name: 'Toast', calories: 80 },
    ] }))
    expect(items).toHaveLength(2)
    expect(items[0]).toEqual({ name: 'Eggs', nutrition: { calories: 140, protein: 12, carbs: 1, fat: 10, fiber: 0, sugar: 0, sodium: 140 } })
    expect(items[1].nutrition.protein).toBe(0)
  })

  test('throws noFunctionCall when the model answered in text', () => {
    expect(() => parseFoodItems({ candidates: [{ content: { parts: [{ text: 'hi' }] } }] })).toThrow(GeminiError)
  })

  test('throws badResponse on a malformed body', () => {
    expect(() => parseFoodItems({})).toThrow(/couldn't parse/i)
  })
})

describe('parseWorkoutCommands', () => {
  test('keeps known actions and drops unknown ones', () => {
    const cmds = parseWorkoutCommands(fnResponse('log_workout', { commands: [
      { action: 'log_set', exercise_name: 'Bench Press', sets: 3, reps: 10, weight_kg: 60 },
      { action: 'dance' },
      { action: 'finish_workout' },
    ] }))
    expect(cmds).toEqual([
      { action: 'log_set', exerciseName: 'Bench Press', sets: 3, reps: 10, weightKg: 60 },
      { action: 'finish_workout' },
    ])
  })
})

describe('callGemini', () => {
  const ok = (body: unknown) => new Response(JSON.stringify(body), { status: 200 })

  test('falls through to the next model on 404 and returns the first success', async () => {
    const fetchImpl = vi.fn()
      .mockResolvedValueOnce(new Response('gone', { status: 404 }))
      .mockResolvedValueOnce(ok({ hello: 1 }))
    const result = await callGemini('key', { contents: [] }, { fetchImpl, sleep: async () => {} })
    expect(result).toEqual({ hello: 1 })
    expect(fetchImpl.mock.calls[1][0]).toContain(MODEL_FALLBACKS[1])
    expect(fetchImpl.mock.calls[0][1].headers['x-goog-api-key']).toBe('key')
  })

  test('does not retry a 400 and surfaces it', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(new Response('bad key', { status: 400 }))
    await expect(callGemini('key', {}, { fetchImpl, sleep: async () => {} })).rejects.toThrow(/400/)
    expect(fetchImpl).toHaveBeenCalledTimes(1)
  })

  test('reports overload with a friendly message after exhausting retries', async () => {
    const fetchImpl = vi.fn().mockImplementation(async () => new Response('busy', { status: 503 }))
    await expect(callGemini('key', {}, { fetchImpl, sleep: async () => {} })).rejects.toThrow(/overloaded/)
    expect(fetchImpl).toHaveBeenCalledTimes(MODEL_FALLBACKS.length * 2)
  })

  test('requires an API key', async () => {
    await expect(callGemini('', {}, {})).rejects.toThrow(/API key/)
  })
})
