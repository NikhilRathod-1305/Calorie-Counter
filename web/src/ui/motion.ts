/** True when the user asked the OS to minimise motion. */
export const prefersReducedMotion = (): boolean =>
  typeof window !== 'undefined' && !!window.matchMedia?.('(prefers-reduced-motion: reduce)').matches

/** Pixels a sheet must be dragged, or the release speed (px/ms), before it dismisses. */
export const DISMISS_DISTANCE = 110
export const DISMISS_VELOCITY = 0.6

/** Decides whether a downward drag on a sheet should close it. */
export function shouldDismiss(dy: number, velocity: number): boolean {
  if (dy <= 0) return false
  return dy >= DISMISS_DISTANCE || velocity >= DISMISS_VELOCITY
}
