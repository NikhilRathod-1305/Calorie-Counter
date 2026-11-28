import { createContext, useCallback, useContext, useEffect, useId, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { prefersReducedMotion } from './motion'

export function Segmented<T extends string>({ options, value, onChange, labels, label }: { options: readonly T[]; value: T; onChange: (v: T) => void; labels?: Partial<Record<T, string>>; label?: string }) {
  return (
    <div className="segmented" role="group" aria-label={label} style={{ '--n': options.length, '--i': Math.max(0, options.indexOf(value)) } as CSSProperties}>
      <span className="seg-ind" aria-hidden="true" />
      {options.map((o) => (
        <button key={o} aria-pressed={o === value} onClick={() => onChange(o)}>{labels?.[o] ?? o}</button>
      ))}
    </div>
  )
}

export function Stepper({ value, onChange, step = 0.5, min = 0.25, format = (v: number) => `${v}×` }: { value: number; onChange: (v: number) => void; step?: number; min?: number; format?: (v: number) => string }) {
  const round = (v: number) => Math.round(v * 100) / 100
  return (
    <div className="stepper">
      <button aria-label="Decrease" onClick={() => onChange(Math.max(min, round(value - step)))}>−</button>
      <span>{format(value)}</span>
      <button aria-label="Increase" onClick={() => onChange(round(value + step))}>+</button>
    </div>
  )
}

export function ProgressBar({ value, max, color }: { value: number; max: number; color: string }) {
  const pct = max > 0 ? Math.min(100, (value / max) * 100) : 0
  return <div className="bar"><div style={{ width: `${pct}%`, background: color }} /></div>
}

export function Ring({ progress, size = 160, stroke = 14, color = 'var(--accent)', children }: { progress: number; size?: number; stroke?: number; color?: string; children?: ReactNode }) {
  const r = (size - stroke) / 2
  const c = 2 * Math.PI * r
  const target = Math.max(0, Math.min(1, progress))
  // Start empty and sweep to the value on mount; later changes transition smoothly.
  const [p, setP] = useState(() => (prefersReducedMotion() ? target : 0))
  useEffect(() => { const f = requestAnimationFrame(() => setP(target)); return () => cancelAnimationFrame(f) }, [target])
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }} aria-hidden="true">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--card-alt)" strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={c * (1 - p)} style={{ transition: 'stroke-dashoffset .9s cubic-bezier(.22,1,.36,1), stroke .3s' }} />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>{children}</div>
    </div>
  )
}

export function NumberField({ label, value, onChange, suffix, step = 'any', placeholder }: { label: string; value: number | undefined; onChange: (v: number | undefined) => void; suffix?: string; step?: string; placeholder?: string }) {
  const id = useId()
  return (
    <div className="field">
      <label htmlFor={id}>{label}{suffix ? ` (${suffix})` : ''}</label>
      <input id={id} className="input" type="number" inputMode="decimal" step={step} placeholder={placeholder}
        value={value ?? ''} onChange={(e) => onChange(e.target.value === '' ? undefined : Number(e.target.value))} />
    </div>
  )
}

export const ErrorBox = ({ message }: { message: string | null }) => (message ? <div className="error-box" role="alert">{message}</div> : null)

export const errorMessage = (e: unknown): string => (e instanceof Error ? e.message : String(e))

/** Number that counts smoothly to its new value. */
export function AnimatedNumber({ value, duration = 700 }: { value: number; duration?: number }) {
  const reduced = prefersReducedMotion()
  const [shown, setShown] = useState(0)
  const from = useRef(0)
  useEffect(() => {
    if (reduced) return
    const start = performance.now()
    const a = from.current
    let frame = 0
    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / duration)
      const v = a + (value - a) * (1 - Math.pow(1 - t, 3))
      from.current = v
      setShown(v)
      if (t < 1) frame = requestAnimationFrame(tick)
    }
    frame = requestAnimationFrame(tick)
    return () => cancelAnimationFrame(frame)
  }, [value, duration, reduced])
  return <>{Math.round(reduced ? value : shown)}</>
}

// ---- Toast ----
export interface ToastAction { label: string; onClick: () => void }
type ShowToast = (msg: string, action?: ToastAction) => void
const ToastContext = createContext<ShowToast>(() => {})
export const useToast = () => useContext(ToastContext)

const TOAST_MS = 1800
const TOAST_ACTION_MS = 4500
const TOAST_EXIT_MS = 220

interface ToastState { id: number; msg: string; action?: ToastAction; leaving: boolean }

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toast, setToast] = useState<ToastState | null>(null)
  const timers = useRef<number[]>([])
  const clear = () => { timers.current.forEach((t) => window.clearTimeout(t)); timers.current = [] }
  const dismiss = useCallback(() => {
    clear()
    setToast((t) => (t ? { ...t, leaving: true } : t))
    timers.current.push(window.setTimeout(() => setToast(null), TOAST_EXIT_MS))
  }, [])
  const show = useCallback<ShowToast>((msg, action) => {
    clear()
    setToast({ id: Date.now(), msg, action, leaving: false })
    timers.current.push(window.setTimeout(dismiss, action ? TOAST_ACTION_MS : TOAST_MS))
  }, [dismiss])
  return (
    <ToastContext.Provider value={show}>
      {children}
      {toast && (
        <div key={toast.id} className={`toast${toast.leaving ? ' leaving' : ''}`} role="status">
          <span>{toast.msg}</span>
          {toast.action && <button className="toast-action" onClick={() => { toast.action?.onClick(); dismiss() }}>{toast.action.label}</button>}
        </div>
      )}
    </ToastContext.Provider>
  )
}
