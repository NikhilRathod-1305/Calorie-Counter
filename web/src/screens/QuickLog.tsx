import { useState } from 'react'
import { Sheet } from '../ui/Sheet'
import { useToast } from '../ui/controls'
import { LogFood, type LogMode } from './log/LogFood'
import { LogWater } from './LogWater'
import { LogExercise } from './LogExercise'

type Panel = { kind: 'food'; mode: LogMode } | { kind: 'water' } | { kind: 'exercise' } | null

const TILES: { emoji: string; label: string; panel: Exclude<Panel, null> }[] = [
  { emoji: '🍽️', label: 'Log Food', panel: { kind: 'food', mode: 'browse' } },
  { emoji: '🏷️', label: 'Barcode Scan', panel: { kind: 'food', mode: 'barcode' } },
  { emoji: '🎙️', label: 'Voice Log', panel: { kind: 'food', mode: 'voice' } },
  { emoji: '📸', label: 'Scan Meal', panel: { kind: 'food', mode: 'photo' } },
  { emoji: '💧', label: 'Water', panel: { kind: 'water' } },
  { emoji: '🔥', label: 'Calories Burned', panel: { kind: 'exercise' } },
]

export function QuickLog({ onClose, onStartWorkout }: { onClose: () => void; onStartWorkout: () => void }) {
  const toast = useToast()
  const [panel, setPanel] = useState<Panel>(null)
  const done = (msg = 'Added to Diary') => { toast(msg); onClose() }

  return (
    <>
      <Sheet title="Quick Log" onClose={onClose}>
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
      </Sheet>
      {panel?.kind === 'food' && <LogFood initialMode={panel.mode} onClose={() => setPanel(null)} onAdded={() => done()} />}
      {panel?.kind === 'water' && <LogWater onClose={() => setPanel(null)} onSaved={() => done('Water logged')} />}
      {panel?.kind === 'exercise' && <LogExercise onClose={() => setPanel(null)} onSaved={() => done('Exercise logged')} />}
    </>
  )
}
