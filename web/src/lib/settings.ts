const API_KEY = 'com.countonme.geminiKey'

/** The Gemini key stays on this device only (localStorage), like the iOS Keychain storage. */
export const loadApiKey = (): string => localStorage.getItem(API_KEY) ?? ''
export const saveApiKey = (key: string): void => {
  const trimmed = key.trim()
  if (trimmed) localStorage.setItem(API_KEY, trimmed)
  else localStorage.removeItem(API_KEY)
}
