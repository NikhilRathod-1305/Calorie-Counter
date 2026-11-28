import { useEffect, useRef, useState, type PointerEvent as ReactPointerEvent } from 'react'

export const LONG_PRESS_MS = 450
const MOVE_TOLERANCE_PX = 12

/**
 * Tap runs `onTap`; holding for LONG_PRESS_MS runs `onLongPress` instead (and swallows the tap).
 * `holding` is true while the finger is down, for a visual cue.
 */
export function useLongPress(onTap: () => void, onLongPress: () => void) {
  const timer = useRef<number | undefined>(undefined)
  const fired = useRef(false)
  const start = useRef<{ x: number; y: number } | null>(null)
  const [holding, setHolding] = useState(false)

  const cancel = () => { window.clearTimeout(timer.current); start.current = null; setHolding(false) }
  useEffect(() => () => window.clearTimeout(timer.current), [])

  return {
    holding,
    handlers: {
      onPointerDown: (e: ReactPointerEvent) => {
        fired.current = false
        start.current = { x: e.clientX, y: e.clientY }
        setHolding(true)
        timer.current = window.setTimeout(() => { fired.current = true; setHolding(false); onLongPress() }, LONG_PRESS_MS)
      },
      onPointerMove: (e: ReactPointerEvent) => {
        const s = start.current
        if (s && Math.hypot(e.clientX - s.x, e.clientY - s.y) > MOVE_TOLERANCE_PX) cancel()
      },
      onPointerUp: cancel,
      onPointerLeave: cancel,
      onPointerCancel: cancel,
      onContextMenu: (e: React.MouseEvent) => e.preventDefault(),
      onClick: () => { if (fired.current) { fired.current = false; return } onTap() },
    },
  }
}
