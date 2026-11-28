import { useState } from 'react'
import { Sheet } from '../ui/Sheet'
import { useToast } from '../ui/controls'
import { LogFood, type LogMode } from './log/LogFood'
import { LogWater } from './LogWater'
import { LogExercise } from './LogExercise'
import type { QuickAction } from '../lib/prefs'

export type Panel = { kind: 'food'; mode: LogMode } | { kind: 'water' } | { kind: 'exercise' } | null

/** The Quick Log panel a shortcut (long-press, launch screen) opens directly. */
export const panelFor = (action: QuickAction): Exclude<Panel, null> =>
  action === 'water' ? { kind: 'water' } : { kind: 'food', mode: action }

const TILES: { emoji: string; label: string; panel: Exclude<Panel, null> }[] = [
  { emoji: '🍽️', label: 'Log Food', panel: { kind: 'food', mode: 'browse' } },
  { emoji: '🏷️', label: 'Barcode Scan', panel: { kind: 'food', mode: 'barcode' } },
  { emoji: '🎙️', label: 'Voice Log', panel: { kind: 'food', mode: 'voice' } },
  { emoji: '📸', label: 'Scan Meal', panel: { kind: 'food', mode: 'photo' } },
  { emoji: '💧', label: 'Water', panel: { kind: 'water' } },
  { emoji: '🔥', label: 'Calories Burned', panel: { kind: 'exercise' } },
]

export function QuickLog({ initial = null, onClose, onStartWorkout }: { initial?: Panel; onClose: () => void; onStartWorkout: () => void }) {
  const toast = useToast()
  const [panel, setPanel] = useState<Panel>(initial)
  // Opened straight into a panel by a shortcut: closing it leaves Quick Log entirely.
  const closePanel = () => (initial ? onClose() : setPanel(null))
  const done = (msg = 'Added to Diary') => { toast(msg); onClose() }

  return (
    <>
      {!panel && <Sheet title="Quick Log" onClose={onClose}>
        <div className="tile-grid">
          {TILES.map((t) => (
            <button key={t.label} className="tile" onClick={() => setPanel(t.panel)}>
              <span className="emoji" aria-hidden="true">{t.emoji}</span>{t.label}
            </button>
          ))}
          <button className="tile" style={{ gridColumn: 'span 2' }} onClick={() => { onClose(); onStartWorkout() }}>
            <span className="emoji" aria-hidden="true">🏋️</span>Start Workout
          </button>
        </div>
      </Sheet>}
      {panel?.kind === 'food' && <LogFood initialMode={panel.mode} onClose={closePanel} onAdded={() => done()} />}
      {panel?.kind === 'water' && <LogWater onClose={closePanel} onSaved={() => done('Water logged')} />}
      {panel?.kind === 'exercise' && <LogExercise onClose={closePanel} onSaved={() => done('Exercise logged')} />}
    </>
  )
}
