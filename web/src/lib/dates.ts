export const DAY_MS = 86_400_000

export function startOfDay(t: number | Date): number {
  const d = new Date(t)
  d.setHours(0, 0, 0, 0)
  return d.getTime()
}

export const endOfDay = (t: number | Date): number => startOfDay(t) + DAY_MS - 1
export const isSameDay = (a: number, b: number): boolean => startOfDay(a) === startOfDay(b)
export const addDays = (t: number, days: number): number => {
  const d = new Date(t)
  d.setDate(d.getDate() + days)
  return d.getTime()
}

/** Puts a time-of-day from `now` onto the given day, so logging for a past day keeps a sensible time. */
export function onDay(day: number, now = new Date()): number {
  const d = new Date(day)
  d.setHours(now.getHours(), now.getMinutes(), now.getSeconds(), 0)
  return d.getTime()
}

export const fmtTime = (t: number) => new Date(t).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
export const fmtDay = (t: number) => new Date(t).toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })
export const fmtShort = (t: number) => new Date(t).toLocaleDateString([], { month: 'short', day: 'numeric' })

export function dayLabel(t: number, now = Date.now()): string {
  if (isSameDay(t, now)) return 'Today'
  if (isSameDay(t, addDays(now, -1))) return 'Yesterday'
  if (isSameDay(t, addDays(now, 1))) return 'Tomorrow'
  return fmtDay(t)
}
