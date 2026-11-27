import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../lib/db'
import { addDays, dayLabel, endOfDay, isSameDay, startOfDay } from '../lib/dates'
import { entryTotal, formatServings, sumNutrition } from '../lib/nutrition'
import { MEAL_EMOJI, MEAL_TYPES, type MealEntry, type MealType } from '../lib/types'
import { estimateSessionCalories } from '../lib/workout'
import { useProfile } from '../hooks'
import { ProgressBar, Ring, useToast } from '../ui/controls'
import { LogFood } from './log/LogFood'
import { EditEntry } from './log/EditEntry'

export function Home() {
  const { profile, goals } = useProfile()
  const toast = useToast()
  const [day, setDay] = useState(() => startOfDay(Date.now()))
  const [addingTo, setAddingTo] = useState<MealType | null>(null)
  const [editing, setEditing] = useState<MealEntry | null>(null)

  const meals = useLiveQuery(() => db.meals.where('timestamp').between(day, endOfDay(day), true, true).sortBy('timestamp'), [day]) ?? []
  const exercise = useLiveQuery(() => db.exercise.where('timestamp').between(day, endOfDay(day), true, true).toArray(), [day]) ?? []
  const workouts = useLiveQuery(() => db.workouts.where('startedAt').between(day, endOfDay(day), true, true).toArray(), [day]) ?? []

  const totals = sumNutrition(meals.map(entryTotal))
  const burned = Math.round(
    exercise.reduce((s, e) => s + e.calories, 0) +
    workouts.filter((w) => w.endedAt).reduce((s, w) => s + estimateSessionCalories(w, profile.weightKg), 0),
  )
  const remaining = goals.calorieGoal - Math.round(totals.calories) + burned

  return (
    <div className="screen">
      <div className="row" style={{ marginBottom: 10 }}>
        <h1 className="screen-title" style={{ margin: 0 }}>{dayLabel(day)}</h1>
        <span className="spacer" />
        {!isSameDay(day, Date.now()) && <button className="chip" onClick={() => setDay(startOfDay(Date.now()))}>Today</button>}
      </div>
      <WeekStrip day={day} onPick={setDay} />

      <div className="stack" style={{ marginTop: 16 }}>
        <div className="card card-pad">
          <div className="row" style={{ justifyContent: 'space-between' }}>
            <Stat label="Goal" value={goals.calorieGoal} />
            <Ring progress={goals.calorieGoal ? totals.calories / (goals.calorieGoal + burned) : 0} size={140} color={remaining < 0 ? 'var(--danger)' : 'var(--accent)'}>
              <div className="num" style={{ fontSize: 30, fontWeight: 700 }}>{Math.abs(remaining)}</div>
              <div className="small muted">{remaining < 0 ? 'over' : 'remaining'}</div>
            </Ring>
            <div className="stack" style={{ gap: 10 }}>
              <Stat label="Food" value={Math.round(totals.calories)} />
              <Stat label="Exercise" value={burned} />
            </div>
          </div>
          <div className="grid-3" style={{ marginTop: 16 }}>
            <Macro label="Carbs" value={totals.carbs} goal={goals.carbG} color="var(--carbs)" />
            <Macro label="Protein" value={totals.protein} goal={goals.proteinG} color="var(--protein)" />
            <Macro label="Fat" value={totals.fat} goal={goals.fatG} color="var(--fat)" />
          </div>
        </div>

        {MEAL_TYPES.map((meal) => {
          const list = meals.filter((m) => m.mealType === meal)
          const kcal = Math.round(list.reduce((s, m) => s + entryTotal(m).calories, 0))
          return (
            <div className="card" key={meal}>
              <div className="row" style={{ padding: 14 }}>
                <span style={{ fontSize: 32, width: 44, textAlign: 'center' }} aria-hidden="true">{MEAL_EMOJI[meal]}</span>
                <div style={{ flex: 1 }}>
                  <div className="bold">{meal}</div>
                  <div className="small muted">{list.length ? `${kcal} kcal` : 'No entries yet'}</div>
                </div>
                <button className="plus-btn" aria-label={`Add to ${meal}`} onClick={() => setAddingTo(meal)}>+</button>
              </div>
              {list.map((m) => (
                <button className="list-row" key={m.id} onClick={() => setEditing(m)}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{m.name}</div>
                    <div className="tiny faint">{servingText(m)}</div>
                  </div>
                  <span className="small muted">{Math.round(entryTotal(m).calories)} cal</span>
                </button>
              ))}
            </div>
          )
        })}
      </div>

      {addingTo && (
        <LogFood mealType={addingTo} day={day} onClose={() => setAddingTo(null)} onAdded={() => { toast(`Added to ${addingTo}`); setAddingTo(null) }} />
      )}
      {editing && <EditEntry entry={editing} onClose={() => setEditing(null)} />}
    </div>
  )
}

function servingText(m: MealEntry): string {
  if (m.items.length > 1) return `${m.items.length} items`
  const it = m.items[0]
  if (!it) return ''
  return it.servingLabel ? `${formatServings(it.servings)} × ${it.servingLabel}` : it.servings === 1 ? '1 portion' : `${formatServings(it.servings)}× portion`
}

const Stat = ({ label, value }: { label: string; value: number }) => (
  <div className="center"><div className="num bold" style={{ fontSize: 18 }}>{value}</div><div className="tiny muted">{label}</div></div>
)

const Macro = ({ label, value, goal, color }: { label: string; value: number; goal: number; color: string }) => (
  <div>
    <div className="tiny muted" style={{ marginBottom: 4 }}>{label}</div>
    <ProgressBar value={value} max={goal} color={color} />
    <div className="tiny" style={{ marginTop: 4 }}><span className="bold">{Math.round(value)}</span><span className="muted"> / {goal}g</span></div>
  </div>
)

function WeekStrip({ day, onPick }: { day: number; onPick: (d: number) => void }) {
  const start = addDays(day, -((new Date(day).getDay() + 6) % 7)) // Monday
  const days = Array.from({ length: 7 }, (_, i) => addDays(start, i))
  return (
    <div className="row" style={{ gap: 4 }}>
      <button className="icon-btn" aria-label="Previous week" onClick={() => onPick(addDays(day, -7))}>‹</button>
      <div className="date-strip" style={{ flex: 1 }}>
        {days.map((d) => (
          <button key={d} className="date-cell" aria-pressed={isSameDay(d, day)} onClick={() => onPick(d)}>
            {new Date(d).toLocaleDateString([], { weekday: 'narrow' })}
            <span className="d">{new Date(d).getDate()}</span>
          </button>
        ))}
      </div>
      <button className="icon-btn" aria-label="Next week" onClick={() => onPick(addDays(day, 7))}>›</button>
    </div>
  )
}
