/** Small device-only app preferences (badge, launch screen, + long-press), kept in localStorage. */

export const BADGE_MODES = ['off', 'calories', 'water', 'meals'] as const
export type BadgeMode = (typeof BADGE_MODES)[number]

/** Log screens the app can jump straight to. */
export const QUICK_ACTIONS = ['voice', 'photo', 'text', 'barcode', 'browse', 'water'] as const
export type QuickAction = (typeof QUICK_ACTIONS)[number]

export const LAUNCH_ACTIONS = ['home', 'quicklog', ...QUICK_ACTIONS] as const
export type LaunchAction = (typeof LAUNCH_ACTIONS)[number]

export interface Prefs { badge: BadgeMode; launch: LaunchAction; longPress: QuickAction }

export const DEFAULT_PREFS: Prefs = { badge: 'off', launch: 'home', longPress: 'voice' }

export const ACTION_LABELS: Record<LaunchAction, string> = {
  home: 'Home', quicklog: 'Quick Log menu', voice: 'Voice log', photo: 'Photo log', text: 'Text log',
  barcode: 'Barcode scan', browse: 'Food search', water: 'Log drink',
}
export const BADGE_LABELS: Record<BadgeMode, string> = {
  off: 'Off', calories: 'Calories left', water: 'Glasses of water left', meals: 'Main meals left',
}

const KEY = 'com.countonme.prefs'
const EVENT = 'countonme-prefs'

const pick = <T extends string>(allowed: readonly T[], value: unknown, fallback: T): T =>
  allowed.includes(value as T) ? (value as T) : fallback

/** Parses stored JSON, replacing anything missing or unknown with defaults. */
export function parsePrefs(raw: string | null): Prefs {
  let data: Record<string, unknown> = {}
  try { data = raw ? (JSON.parse(raw) as Record<string, unknown>) ?? {} : {} } catch { data = {} }
  return {
    badge: pick(BADGE_MODES, data.badge, DEFAULT_PREFS.badge),
    launch: pick(LAUNCH_ACTIONS, data.launch, DEFAULT_PREFS.launch),
    longPress: pick(QUICK_ACTIONS, data.longPress, DEFAULT_PREFS.longPress),
  }
}

export const loadPrefs = (): Prefs => parsePrefs(localStorage.getItem(KEY))

export function savePrefs(prefs: Prefs): void {
  localStorage.setItem(KEY, JSON.stringify(prefs))
  window.dispatchEvent(new Event(EVENT))
}

/** For useSyncExternalStore: re-reads when prefs change in this tab or another. */
export function subscribePrefs(onChange: () => void): () => void {
  window.addEventListener(EVENT, onChange)
  window.addEventListener('storage', onChange)
  return () => { window.removeEventListener(EVENT, onChange); window.removeEventListener('storage', onChange) }
}
export const prefsSnapshot = (): string => localStorage.getItem(KEY) ?? ''
