import type { Nutrition } from './nutrition'

export interface BarcodeProduct { name: string; per100g: Nutrition }

/** Looks up a barcode on Open Food Facts. Nutrition is per 100 g/ml; missing values become 0. */
export async function lookupBarcode(barcode: string, fetchImpl: typeof fetch = fetch): Promise<BarcodeProduct> {
  if (!/^\d{6,14}$/.test(barcode)) throw new Error('That barcode looks invalid. Try again.')
  let res: Response
  try {
    res = await fetchImpl(`https://world.openfoodfacts.org/api/v2/product/${barcode}.json`)
  } catch {
    throw new Error('Network error looking up that barcode. Check your connection.')
  }
  if (res.status === 404) throw new Error('No product found for that barcode. Try Text or Browse instead.')
  if (!res.ok) throw new Error(`Barcode lookup failed (status ${res.status}).`)
  const json = (await res.json()) as { status?: number; product?: { product_name?: string; nutriments?: Record<string, unknown> } }
  if (json.status !== 1 || !json.product) throw new Error('No product found for that barcode. Try Text or Browse instead.')
  const nm = json.product.nutriments ?? {}
  const v = (k: string) => Number(nm[k]) || 0
  return {
    name: json.product.product_name?.trim() || 'Unknown product',
    per100g: {
      calories: v('energy-kcal_100g'), protein: v('proteins_100g'), carbs: v('carbohydrates_100g'), fat: v('fat_100g'),
      fiber: v('fiber_100g'), sugar: v('sugars_100g'), sodium: v('sodium_100g') * 1000,
    },
  }
}
