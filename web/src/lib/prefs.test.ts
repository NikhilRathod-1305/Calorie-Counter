import { beforeEach, describe, expect, test } from 'vitest'
import { DEFAULT_PREFS, loadPrefs, parsePrefs, savePrefs } from './prefs'

const store = new Map<string, string>()
beforeEach(() => {
  store.clear()
  Object.assign(globalThis, {
    localStorage: { getItem: (k: string) => store.get(k) ?? null, setItem: (k: string, v: string) => void store.set(k, v), removeItem: (k: string) => void store.delete(k) },
    window: { dispatchEvent: () => true },
  })
})

describe('parsePrefs', () => {
  test('returns defaults for missing or broken data', () => {
    expect(parsePrefs(null)).toEqual(DEFAULT_PREFS)
    expect(parsePrefs('{not json')).toEqual(DEFAULT_PREFS)
  })

  test('keeps valid values and replaces unknown ones with defaults', () => {
    const prefs = parsePrefs(JSON.stringify({ badge: 'water', launch: 'rocket', longPress: 'photo' }))
    expect(prefs).toEqual({ badge: 'water', launch: DEFAULT_PREFS.launch, longPress: 'photo' })
  })
})

describe('savePrefs', () => {
  test('round-trips through localStorage', () => {
    savePrefs({ badge: 'calories', launch: 'quicklog', longPress: 'text' })
    expect(loadPrefs()).toEqual({ badge: 'calories', launch: 'quicklog', longPress: 'text' })
  })
})
