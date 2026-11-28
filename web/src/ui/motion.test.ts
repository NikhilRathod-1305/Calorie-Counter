import { describe, expect, test } from 'vitest'
import { DISMISS_DISTANCE, DISMISS_VELOCITY, shouldDismiss } from './motion'

describe('shouldDismiss', () => {
  test('keeps the sheet open for a short, slow drag', () => {
    expect(shouldDismiss(DISMISS_DISTANCE - 1, DISMISS_VELOCITY / 2)).toBe(false)
  })
  test('dismisses once dragged far enough', () => {
    expect(shouldDismiss(DISMISS_DISTANCE, 0)).toBe(true)
  })
  test('dismisses on a quick flick even when short', () => {
    expect(shouldDismiss(20, DISMISS_VELOCITY)).toBe(true)
  })
  test('never dismisses when dragged upward', () => {
    expect(shouldDismiss(-200, 5)).toBe(false)
  })
})
