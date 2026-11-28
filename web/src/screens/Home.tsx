import { useEffect, useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, newId } from '../lib/db'
import { addDays, dayLabel, endOfDay, fmtTime, isSameDay, startOfDay } from '../lib/dates'
import { entryTotal, formatServings, sumNutrition } from '../lib/nutrition'
import { MEAL_EMOJI, MEAL_TYPES, hydrationMl, type ExerciseLog, type MealEntry, type MealType, type WorkoutSession } from '../lib/types'
import { estimateSessionCalories, sessionMinutes } from '../lib/workout'
import { useProfile } from '../hooks'
import { AnimatedNumber, ProgressBar, Ring, useToast } from '../ui/controls'
import { LogFood } from './log/LogFood'
import { EditEntry } from './log/EditEntry'
import { LogWater } from './LogWater'

const QUICK_WATER_ML = 250

/** Keeps the selected day on "today" across midnight while the app sits in the background. */
function useToday(): [number, (d: number) => void] {
  const [day, setDay] = useState(() => startOfDay(Date.now()))
  const [followToday, setFollowToday] = useState(true)
  useEffect(() => {
    if (!followToday) return
    const sync = () => { if (document.visibilityState === 'visible') setDay(startOfDay(Date.now())) }
    document.addEventListener('visibilitychange', sync)
    const t = window.setInterval(sync, 60_000)
    return () => { document.removeEventListener('visibilitychange', sync); window.clearInterval(t) }
  }, [followToday])
  const pick = (d: number) => { setDay(d); setFollowToday(isSameDay(d, Date.now())) }
  return [day, pick]
}

export function Home() {
  const { profile, goals } = useProfile()
  const toast = useToast()
  const [day, setDay] = useToday()
  const [logWater, setLogWater] = useState(false)
  const [addingTo, setAddingTo] = useState<MealType | null>(null)
  const [editing, setEditing] = useState<MealEntry | null>(null)

  const meals = useLiveQuery(() => db.meals.where('timestamp').between(day, endOfDay(day), true, true).sortBy('timestamp'), [day]) ?? []
  const exercise = useLiveQuery(() => db.exercise.where('timestamp').between(day, endOfDay(day), true, true).toArray(), [day]) ?? []
  const workouts = useLiveQuery(() => db.workouts.where('startedAt').between(day, endOfDay(day), true, true).toArray(), [day]) ?? []
  const water = useLiveQuery(() => db.water.where('timestamp').between(day, endOfDay(day), true, true).toArray(), [day]) ?? []
  const waterMl = Math.round(water.reduce((s, w) => s + hydrationMl(w), 0))
  const finished = workouts.filter((w) => w.endedAt)

  const totals = sumNutrition(meals.map(entryTotal))
  const burned = Math.round(
    exercise.reduce((s, e) => s + e.calories, 0) +
    finished.reduce((s, w) => s + estimateSessionCalories(w, profile.weightKg), 0),
  )
  const remaining = goals.calorieGoal - Math.round(totals.calories) + burned

  const addWater = async () => {
    try {
      const id = newId()
      await db.water.add({ id, timestamp: isSameDay(day, Date.now()) ? Date.now() : day + 12 * 3_600_000, ml: QUICK_WATER_ML, drink: 'water' })
      toast(`+${QUICK_WATER_ML} ml water`, { label: 'Undo', onClick: () => void db.water.delete(id) })
    } catch { toast('Could not save water') }
  }

  return (
    <div className="screen">
      <div className="row" style={{ marginBottom: 12 }}>
        <div>
          <h1 className="screen-title" style={{ margin: 0 }}>{dayLabel(day)}</h1>
          <div className="small muted">{new Date(day).toLocaleDateString([], { weekday: 'long', day: 'numeric', month: 'long' })}</div>
        </div>
        <span className="spacer" />
        {!isSameDay(day, Date.now()) && <button className="chip" onClick={() => setDay(startOfDay(Date.now()))}>Today</button>}
      </div>
      <WeekStrip day={day} onPick={setDay} />

      <div className="stack" style={{ marginTop: 16 }}>
        <div className="card card-pad">
          <div className="row" style={{ justifyContent: 'space-between' }}>
            <Stat label="Goal" value={goals.calorieGoal} animate={false} />
            <Ring progress={goals.calorieGoal ? totals.calories / (goals.calorieGoal + burned) : 0} size={140} color={remaining < 0 ? 'var(--danger)' : 'var(--accent)'}>
              <div className="num" style={{ fontSize: 30, fontWeight: 700 }}><AnimatedNumber value={Math.abs(remaining)} /></div>
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

        <div className="card water-card">
          <button className="water-main" onClick={() => setLogWater(true)}>
            <span className="water-emoji" aria-hidden="true">💧</span>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div className="row" style={{ gap: 6 }}><span className="bold">Water</span><span className="small muted"><AnimatedNumber value={waterMl} /> / {profile.waterGoalMl} ml</span></div>
              <div style={{ marginTop: 8 }}><ProgressBar value={waterMl} max={profile.waterGoalMl} color="var(--water)" /></div>
            </div>
          </button>
          <button className="water-add" aria-label={`Add ${QUICK_WATER_ML} ml water`} onClick={() => void addWater()}>+{QUICK_WATER_ML}</button>
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
                <button className="list-row row-enter" key={m.id} onClick={() => setEditing(m)}>
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

        <Activity exercise={exercise} workouts={finished} weightKg={profile.weightKg} burned={burned} />
      </div>

      {addingTo && (
        <LogFood mealType={addingTo} day={day} onClose={() => setAddingTo(null)} onAdded={() => { toast(`Added to ${addingTo}`); setAddingTo(null) }} />
      )}
      {editing && <EditEntry entry={editing} onClose={() => setEditing(null)} />}
      {logWater && <LogWater day={day} onClose={() => setLogWater(false)} onSaved={() => { setLogWater(false); toast('Water logged') }} />}
    </div>
  )
}

function servingText(m: MealEntry): string {
  if (m.items.length > 1) return `${m.items.length} items`
  const it = m.items[0]
  if (!it) return ''
  return it.servingLabel ? `${formatServings(it.servings)} × ${it.servingLabel}` : it.servings === 1 ? '1 portion' : `${formatServings(it.servings)}× portion`
}

const Stat = ({ label, value, animate = true }: { label: string; value: number; animate?: boolean }) => (
  <div className="center"><div className="num bold" style={{ fontSize: 18 }}>{animate ? <AnimatedNumber value={value} /> : value}</div><div className="tiny muted">{label}</div></div>
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
      <button className="icon-btn week-nav" aria-label="Previous week" onClick={() => onPick(addDays(day, -7))}>‹</button>
      <div className="date-strip" style={{ flex: 1 }}>
        {days.map((d) => (
          <button key={d} className="date-cell" aria-pressed={isSameDay(d, day)} onClick={() => onPick(d)}>
            {new Date(d).toLocaleDateString([], { weekday: 'narrow' })}
            <span className="d">{new Date(d).getDate()}</span>
          </button>
        ))}
      </div>
      <button className="icon-btn week-nav" aria-label="Next week" onClick={() => onPick(addDays(day, 7))}>›</button>
    </div>
  )
}

function Activity({ exercise, workouts, weightKg, burned }: { exercise: ExerciseLog[]; workouts: WorkoutSession[]; weightKg: number; burned: number }) {
  const toast = useToast()
  const remove = async (e: ExerciseLog) => {
    try {
      await db.exercise.delete(e.id)
      toast('Activity deleted', { label: 'Undo', onClick: () => void db.exercise.put(e) })
    } catch { toast('Could not delete') }
  }
  return (
    <div className="card">
      <div className="row" style={{ padding: 14 }}>
        <span style={{ fontSize: 32, width: 44, textAlign: 'center' }} aria-hidden="true">🔥</span>
        <div style={{ flex: 1 }}>
          <div className="bold">Activity</div>
          <div className="small muted">{burned ? `${burned} kcal burned` : 'Log exercise from the + button'}</div>
        </div>
      </div>
      {workouts.map((w) => (
        <div className="list-row row-enter" key={w.id}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14 }}>🏋️ {w.name}</div>
            <div className="tiny faint">{fmtTime(w.startedAt)} · {Math.round(sessionMinutes(w))} min · {w.sets.length} sets</div>
          </div>
          <span className="small muted">~{Math.round(estimateSessionCalories(w, weightKg))} cal</span>
        </div>
      ))}
      {exercise.map((e) => (
        <div className="list-row row-enter" key={e.id}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14 }}>{e.name}</div>
            <div className="tiny faint">{fmtTime(e.timestamp)}{e.minutes ? ` · ${e.minutes} min` : ''}</div>
          </div>
          <span className="small muted">{Math.round(e.calories)} cal</span>
          <button className="del-btn" aria-label={`Delete ${e.name}`} onClick={() => void remove(e)}>✕</button>
        </div>
      ))}
    </div>
  )
}
