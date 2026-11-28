import { useCallback, useEffect, useRef, useState, type PointerEvent as ReactPointerEvent, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { prefersReducedMotion, shouldDismiss } from './motion'

interface SheetProps {
  title: string
  onClose: () => void
  children: ReactNode
  full?: boolean
  action?: ReactNode
}

const CLOSE_MS = 240

/**
 * Bottom sheet (or full-screen cover) with a close button. Escape, a tap on the backdrop or
 * dragging the header down closes it with an animation.
 * Portalled to <body>: iOS makes scroll containers their own stacking context,
 * so a sheet rendered inside a screen would sit underneath the tab bar.
 */
export function Sheet({ title, onClose, children, full, action }: SheetProps) {
  const [closing, setClosing] = useState(false)
  const [dragY, setDragY] = useState(0)
  const [dragging, setDragging] = useState(false)
  const drag = useRef<{ startY: number; lastY: number; lastT: number; velocity: number } | null>(null)
  const closeRef = useRef(onClose)
  useEffect(() => { closeRef.current = onClose })

  const requestClose = useCallback(() => {
    if (prefersReducedMotion()) { closeRef.current(); return }
    setClosing(true)
    window.setTimeout(() => closeRef.current(), CLOSE_MS)
  }, [])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') requestClose() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [requestClose])

  const onPointerDown = (e: ReactPointerEvent) => {
    // Full-screen covers (e.g. an active workout) close only via their buttons, never by accident.
    if (full || (e.target as HTMLElement).closest('button, input, select, textarea')) return
    drag.current = { startY: e.clientY, lastY: e.clientY, lastT: e.timeStamp, velocity: 0 }
    ;(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId)
    setDragging(true)
  }
  const onPointerMove = (e: ReactPointerEvent) => {
    const d = drag.current
    if (!d) return
    const dt = Math.max(1, e.timeStamp - d.lastT)
    d.velocity = (e.clientY - d.lastY) / dt
    d.lastY = e.clientY
    d.lastT = e.timeStamp
    setDragY(Math.max(0, e.clientY - d.startY))
  }
  const onPointerUp = () => {
    const d = drag.current
    drag.current = null
    setDragging(false)
    if (!d) return
    if (shouldDismiss(d.lastY - d.startY, d.velocity)) requestClose()
    else setDragY(0)
  }

  return createPortal(
    <div className={`overlay${closing ? ' closing' : ''}`} onClick={(e) => { if (e.target === e.currentTarget) requestClose() }}>
      <div
        className={`sheet${full ? ' full' : ''}${closing ? ' closing' : ''}${dragging && dragY > 0 ? ' dragging' : ''}`}
        role="dialog" aria-modal="true" aria-label={title}
        style={dragY && !closing ? { transform: `translateY(${dragY}px)` } : closing && dragY ? { ['--from' as string]: `${dragY}px` } : undefined}
      >
        <div className="sheet-head" onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} onPointerCancel={onPointerUp}>
          {!full && <span className="grabber" aria-hidden="true" />}
          <h2>{title}</h2>
          {action}
          <button className="icon-btn" onClick={requestClose} aria-label="Close">✕</button>
        </div>
        <div className="sheet-body">{children}</div>
      </div>
    </div>,
    document.body,
  )
}
