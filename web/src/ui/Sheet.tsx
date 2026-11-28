import { useEffect, type ReactNode } from 'react'
import { createPortal } from 'react-dom'

interface SheetProps {
  title: string
  onClose: () => void
  children: ReactNode
  full?: boolean
  action?: ReactNode
}

/**
 * Bottom sheet (or full-screen cover) with a close button; Escape closes it.
 * Portalled to <body>: iOS makes scroll containers their own stacking context,
 * so a sheet rendered inside a screen would sit underneath the tab bar.
 */
export function Sheet({ title, onClose, children, full, action }: SheetProps) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  return createPortal(
    <div className="overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose() }}>
      <div className={`sheet${full ? ' full' : ''}`} role="dialog" aria-modal="true" aria-label={title}>
        <div className="sheet-head">
          <h2>{title}</h2>
          {action}
          <button className="icon-btn" onClick={onClose} aria-label="Close">✕</button>
        </div>
        <div className="sheet-body">{children}</div>
      </div>
    </div>,
    document.body,
  )
}
