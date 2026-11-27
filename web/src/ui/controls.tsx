import { createContext, useCallback, useContext, useId, useRef, useState, type ReactNode } from 'react'

export function Segmented<T extends string>({ options, value, onChange, labels, label }: { options: readonly T[]; value: T; onChange: (v: T) => void; labels?: Partial<Record<T, string>>; label?: string }) {
  return (
    <div className="segmented" role="group" aria-label={label}>
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
  const p = Math.max(0, Math.min(1, progress))
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }} aria-hidden="true">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--card-alt)" strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round"
          strokeDasharray={c} strokeDashoffset={c * (1 - p)} style={{ transition: 'stroke-dashoffset .4s' }} />
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

// ---- Toast ----
const ToastContext = createContext<(msg: string) => void>(() => {})
export const useToast = () => useContext(ToastContext)

const TOAST_MS = 1600

export function ToastProvider({ children }: { children: ReactNode }) {
  const [msg, setMsg] = useState<string | null>(null)
  const timer = useRef<number | undefined>(undefined)
  const show = useCallback((m: string) => {
    setMsg(m)
    window.clearTimeout(timer.current)
    timer.current = window.setTimeout(() => setMsg(null), TOAST_MS)
  }, [])
  return (
    <ToastContext.Provider value={show}>
      {children}
      {msg && <div className="toast" role="status">{msg}</div>}
    </ToastContext.Provider>
  )
}
