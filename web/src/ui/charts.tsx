interface Point { label: string; value: number }

const W = 320
const H = 140
const PAD = { top: 12, bottom: 22, left: 4, right: 4 }

/** Minimal SVG bar chart with an optional dashed goal line. */
export function BarChart({ data, color, goal, unit = '', warnOverGoal = false }: { data: Point[]; color: string; goal?: number; unit?: string; warnOverGoal?: boolean }) {
  const max = Math.max(1, goal ?? 0, ...data.map((d) => d.value)) * 1.1
  const innerH = H - PAD.top - PAD.bottom
  const slot = (W - PAD.left - PAD.right) / Math.max(1, data.length)
  const barW = Math.max(3, slot * 0.6)
  const y = (v: number) => PAD.top + innerH * (1 - v / max)
  const labelEvery = Math.ceil(data.length / 7)
  return (
    <svg viewBox={`0 0 ${W} ${H}`} width="100%" role="img" aria-label={`Bar chart: ${data.map((d) => `${d.label} ${Math.round(d.value)}${unit}`).join(', ')}`}>
      {goal !== undefined && <line x1={PAD.left} x2={W - PAD.right} y1={y(goal)} y2={y(goal)} stroke="var(--text-faint)" strokeDasharray="4 4" />}
      {data.map((d, i) => {
        const x = PAD.left + i * slot + (slot - barW) / 2
        return (
          <g key={i}>
            <rect x={x} y={y(d.value)} width={barW} height={Math.max(0, H - PAD.bottom - y(d.value))} rx={Math.min(4, barW / 2)} fill={warnOverGoal && goal !== undefined && d.value > goal ? 'var(--danger)' : color} opacity={d.value ? 1 : 0.25} />
            {i % labelEvery === 0 && <text x={x + barW / 2} y={H - 6} textAnchor="middle" fontSize="10" fill="var(--text-3)">{d.label}</text>}
          </g>
        )
      })}
    </svg>
  )
}

/** Minimal SVG line chart; y-axis fits the data range. */
export function LineChart({ data, color, unit = '' }: { data: Point[]; color: string; unit?: string }) {
  if (data.length === 0) return null
  const vals = data.map((d) => d.value)
  const lo = Math.min(...vals)
  const hi = Math.max(...vals)
  const span = Math.max(1, hi - lo)
  const innerH = H - PAD.top - PAD.bottom
  const x = (i: number) => PAD.left + 16 + (data.length === 1 ? (W - 40) / 2 : (i * (W - PAD.left - PAD.right - 32)) / (data.length - 1))
  const y = (v: number) => PAD.top + innerH * (1 - (v - lo + span * 0.1) / (span * 1.2))
  const path = data.map((d, i) => `${i ? 'L' : 'M'}${x(i)},${y(d.value)}`).join(' ')
  const labelEvery = Math.ceil(data.length / 6)
  return (
    <svg viewBox={`0 0 ${W} ${H}`} width="100%" role="img" aria-label={`Line chart: ${data.map((d) => `${d.label} ${d.value}${unit}`).join(', ')}`}>
      <path d={path} fill="none" stroke={color} strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
      {data.map((d, i) => (
        <g key={i}>
          <circle cx={x(i)} cy={y(d.value)} r="3.5" fill="var(--card)" stroke={color} strokeWidth="2" />
          {i % labelEvery === 0 && <text x={x(i)} y={H - 6} textAnchor="middle" fontSize="10" fill="var(--text-3)">{d.label}</text>}
        </g>
      ))}
    </svg>
  )
}
