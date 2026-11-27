import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, newId } from '../lib/db'
import { addDays, endOfDay, fmtDay, fmtShort, isSameDay, startOfDay } from '../lib/dates'
import { bmi, bmiCategory } from '../lib/goals'
import { entryTotal, sumNutrition } from '../lib/nutrition'
import { hydrationMl } from '../lib/types'
import { useLatestWeight, useProfile } from '../hooks'
import { BarChart, LineChart } from '../ui/charts'
import { ErrorBox, ProgressBar, Segmented, errorMessage, useToast } from '../ui/controls'
import { Sheet } from '../ui/Sheet'
import { LogWater } from './LogWater'

type Range = '7D' | '30D'
const RANGE_DAYS: Record<Range, number> = { '7D': 7, '30D': 30 }

export function Tracker() {
  const { profile, goals } = useProfile()
  const toast = useToast()
  const [range, setRange] = useState<Range>('7D')
  const [logWater, setLogWater] = useState(false)
  const [logWeight, setLogWeight] = useState(false)
  const today = startOfDay(Date.now())
  const from = addDays(today, -(RANGE_DAYS[range] - 1))

  const meals = useLiveQuery(() => db.meals.where('timestamp').between(from, endOfDay(today), true, true).toArray(), [from, today]) ?? []
  const water = useLiveQuery(() => db.water.where('timestamp').between(from, endOfDay(today), true, true).toArray(), [from, today]) ?? []
  const weights = useLiveQuery(() => db.weights.orderBy('timestamp').toArray()) ?? []
  const currentKg = useLatestWeight(profile.weightKg)

  const days = Array.from({ length: RANGE_DAYS[range] }, (_, i) => addDays(from, i))
  const label = (d: number) => (range === '7D' ? new Date(d).toLocaleDateString([], { weekday: 'short' }) : String(new Date(d).getDate()))
  const caloriesByDay = days.map((d) => ({ label: label(d), value: meals.filter((m) => isSameDay(m.timestamp, d)).reduce((s, m) => s + entryTotal(m).calories, 0) }))
  const waterByDay = days.map((d) => ({ label: label(d), value: water.filter((w) => isSameDay(w.timestamp, d)).reduce((s, w) => s + hydrationMl(w), 0) }))
  const waterToday = Math.round(waterByDay[waterByDay.length - 1]?.value ?? 0)
  const loggedDays = caloriesByDay.filter((d) => d.value > 0)
  const avgCalories = loggedDays.length ? Math.round(loggedDays.reduce((s, d) => s + d.value, 0) / loggedDays.length) : 0
  const totals = sumNutrition(meals.map(entryTotal))
  const macroSum = totals.protein * 4 + totals.carbs * 4 + totals.fat * 9
  const recentWeights = weights.slice(-12).map((w) => ({ label: fmtShort(w.timestamp), value: Math.round(w.kg * 10) / 10 }))
  const bmiValue = bmi(profile, currentKg)

  return (
    <div className="screen">
      <h1 className="screen-title">Tracker</h1>
      <div className="stack">
        <div className="grid-2">
          <button className="card card-pad" style={{ textAlign: 'left' }} onClick={() => setLogWater(true)}>
            <div className="small muted">💧 Water today</div>
            <div className="num bold" style={{ fontSize: 24, color: 'var(--water)', margin: '4px 0 8px' }}>{waterToday}<span className="small muted"> / {profile.waterGoalMl} ml</span></div>
            <ProgressBar value={waterToday} max={profile.waterGoalMl} color="var(--water)" />
          </button>
          <button className="card card-pad" style={{ textAlign: 'left' }} onClick={() => setLogWeight(true)}>
            <div className="small muted">⚖️ Weight</div>
            <div className="num bold" style={{ fontSize: 24, color: 'var(--weight)', margin: '4px 0 2px' }}>{currentKg.toFixed(1)}<span className="small muted"> kg</span></div>
            <div className="tiny faint">Goal {profile.targetWeightKg} kg · BMI {bmiValue.toFixed(1)} ({bmiCategory(bmiValue)})</div>
          </button>
        </div>

        <Segmented options={['7D', '30D'] as const} value={range} onChange={setRange} />

        <div className="card card-pad">
          <div className="row"><span className="bold">Calories</span><span className="spacer" /><span className="small muted">avg {avgCalories} / goal {goals.calorieGoal}</span></div>
          <BarChart data={caloriesByDay} color="var(--secondary)" goal={goals.calorieGoal} unit=" kcal" warnOverGoal />
        </div>

        <div className="card card-pad">
          <div className="bold" style={{ marginBottom: 10 }}>Macro split</div>
          {macroSum === 0 ? <div className="small muted">No food logged in this range.</div> : (
            <div className="stack" style={{ gap: 10 }}>
              {([['Carbs', totals.carbs * 4, 'var(--carbs)'], ['Protein', totals.protein * 4, 'var(--protein)'], ['Fat', totals.fat * 9, 'var(--fat)']] as const).map(([name, kcal, color]) => (
                <div key={name}>
                  <div className="row small"><span>{name}</span><span className="spacer" /><span className="bold">{Math.round((kcal / macroSum) * 100)}%</span></div>
                  <ProgressBar value={kcal} max={macroSum} color={color} />
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="card card-pad">
          <div className="row"><span className="bold">Hydration</span><span className="spacer" /><span className="small muted">goal {profile.waterGoalMl} ml</span></div>
          <BarChart data={waterByDay} color="var(--water)" goal={profile.waterGoalMl} unit=" ml" />
        </div>

        <div className="card card-pad">
          <div className="row"><span className="bold">Weight trend</span><span className="spacer" /><button className="chip" onClick={() => setLogWeight(true)}>＋ Log</button></div>
          {recentWeights.length < 2 ? <div className="small muted" style={{ marginTop: 8 }}>Log your weight a few times to see a trend.</div> : <LineChart data={recentWeights} color="var(--weight)" unit=" kg" />}
        </div>
        <WeightHistory />
      </div>
      {logWater && <LogWater onClose={() => setLogWater(false)} onSaved={() => { setLogWater(false); toast('Water logged') }} />}
      {logWeight && <LogWeight currentKg={currentKg} onClose={() => setLogWeight(false)} onSaved={() => { setLogWeight(false); toast('Weight logged') }} />}
    </div>
  )
}

function WeightHistory() {
  const recent = useLiveQuery(() => db.weights.orderBy('timestamp').reverse().limit(10).toArray()) ?? []
  if (recent.length === 0) return null
  return (
    <div className="card">
      {recent.map((w) => (
        <div className="list-row" key={w.id}>
          <span style={{ flex: 1 }} className="small">{fmtDay(w.timestamp)}</span>
          <span className="num bold">{w.kg.toFixed(1)} kg</span>
          <button className="swipe-del" aria-label={`Delete weight from ${fmtDay(w.timestamp)}`} onClick={() => db.weights.delete(w.id)}>✕</button>
        </div>
      ))}
    </div>
  )
}

const MIN_KG = 20
const MAX_KG = 400

function LogWeight({ currentKg, onClose, onSaved }: { currentKg: number; onClose: () => void; onSaved: () => void }) {
  const [kg, setKg] = useState(String(currentKg.toFixed(1)))
  const [error, setError] = useState<string | null>(null)
  const save = async () => {
    const value = Number(kg)
    if (!(value >= MIN_KG && value <= MAX_KG)) return setError(`Enter a weight between ${MIN_KG} and ${MAX_KG} kg.`)
    try { await db.weights.add({ id: newId(), timestamp: Date.now(), kg: value }); onSaved() } catch (e) { setError(errorMessage(e)) }
  }
  return (
    <Sheet title="Log Weight" onClose={onClose}>
      <div className="stack">
        <input className="input num" style={{ fontSize: 32, textAlign: 'center', minHeight: 70 }} type="number" inputMode="decimal" step="0.1" value={kg} onChange={(e) => setKg(e.target.value)} aria-label="Weight in kg" />
        <div className="center small muted">kilograms · {fmtDay(Date.now())}</div>
        <ErrorBox message={error} />
        <button className="btn btn-primary btn-block" style={{ background: 'var(--weight)' }} onClick={save}>Save</button>
      </div>
    </Sheet>
  )
}

