import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, newId } from '../lib/db'
import { endOfDay, startOfDay } from '../lib/dates'
import { CUP_SIZES, DRINKS, hydrationMl, type DrinkType } from '../lib/types'
import { useProfile } from '../hooks'
import { Sheet } from '../ui/Sheet'
import { ErrorBox, ProgressBar, errorMessage } from '../ui/controls'

const DEFAULT_CUP_ML = 250

export function LogWater({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const { profile } = useProfile()
  const [drink, setDrink] = useState<DrinkType>('water')
  const [ml, setMl] = useState<number>(DEFAULT_CUP_ML)
  const [error, setError] = useState<string | null>(null)
  const today = startOfDay(Date.now())
  const logs = useLiveQuery(() => db.water.where('timestamp').between(today, endOfDay(today), true, true).toArray(), [today]) ?? []
  const total = Math.round(logs.reduce((s, w) => s + hydrationMl(w), 0))

  const save = async () => {
    try { await db.water.add({ id: newId(), timestamp: Date.now(), ml, drink }); onSaved() } catch (e) { setError(errorMessage(e)) }
  }

  return (
    <Sheet title="Log Drink" onClose={onClose}>
      <div className="stack">
        <div className="card card-pad">
          <div className="row"><span className="num bold" style={{ fontSize: 24, color: 'var(--water)' }}>{total} ml</span><span className="muted small">of {profile.waterGoalMl} ml today</span></div>
          <div style={{ marginTop: 10 }}><ProgressBar value={total} max={profile.waterGoalMl} color="var(--water)" /></div>
        </div>
        <div className="section-label">Drink</div>
        <div className="drink-grid">
          {(Object.keys(DRINKS) as DrinkType[]).map((d) => (
            <button key={d} className="drink" aria-pressed={drink === d} onClick={() => setDrink(d)}>
              <span className="emoji" aria-hidden="true">{DRINKS[d].emoji}</span>{DRINKS[d].label}
            </button>
          ))}
        </div>
        <div className="section-label">Amount</div>
        <div className="grid-3" style={{ gap: 8 }}>
          {CUP_SIZES.map((s) => <button key={s} className="chip" style={{ justifyContent: 'center' }} aria-pressed={ml === s} onClick={() => setMl(s)}>{s} ml</button>)}
        </div>
        {DRINKS[drink].factor < 1 && <div className="tiny faint">{DRINKS[drink].label} counts {Math.round(DRINKS[drink].factor * 100)}% toward hydration.</div>}
        <ErrorBox message={error} />
        <button className="btn btn-primary btn-block" style={{ background: 'var(--water)' }} onClick={save}>Add {ml} ml</button>
      </div>
    </Sheet>
  )
}
