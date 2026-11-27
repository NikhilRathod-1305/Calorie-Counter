import { describe, expect, test, vi } from 'vitest'
import { lookupBarcode } from './openFoodFacts'

describe('lookupBarcode', () => {
  test('maps per-100g nutriments and converts sodium to mg', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(new Response(JSON.stringify({ status: 1, product: { product_name: 'Oat Bar', nutriments: { 'energy-kcal_100g': 400, proteins_100g: '10', sodium_100g: 0.3 } } })))
    const p = await lookupBarcode('5000159484695', fetchImpl)
    expect(p.name).toBe('Oat Bar')
    expect(p.per100g).toMatchObject({ calories: 400, protein: 10, sodium: 300, fat: 0 })
  })

  test('reports a missing product clearly', async () => {
    const fetchImpl = vi.fn().mockResolvedValue(new Response(JSON.stringify({ status: 0 })))
    await expect(lookupBarcode('12345678', fetchImpl)).rejects.toThrow(/No product found/)
  })

  test('rejects non-numeric barcodes without a network call', async () => {
    const fetchImpl = vi.fn()
    await expect(lookupBarcode('abc', fetchImpl)).rejects.toThrow(/invalid/)
    expect(fetchImpl).not.toHaveBeenCalled()
  })
})
