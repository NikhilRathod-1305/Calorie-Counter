import { useMemo, useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../../lib/db'
import { foodToItem, libraryFoods, searchFoods } from '../../lib/meals'
import type { EntryItem } from '../../lib/nutrition'
import type { FoodItem } from '../../lib/types'
import { CreateFood } from './CreateFood'

const CATEGORIES = ['Fruits', 'Vegetables', 'Grains', 'Protein', 'Dairy', 'Snacks', 'Beverages', 'Fast Food', 'Desserts', 'Other']
const RESULT_LIMIT = 80
const NO_FOODS: FoodItem[] = []

export function BrowseFoods({ onPick }: { onPick: (items: EntryItem[]) => void }) {
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState<string | null>(null)
  const [creating, setCreating] = useState(false)
  const custom = useLiveQuery(() => db.customFoods.orderBy('name').toArray()) ?? NO_FOODS

  const results = useMemo(() => searchFoods([...custom, ...libraryFoods], query, category).slice(0, RESULT_LIMIT), [custom, query, category])

  return (
    <div className="stack">
      <input className="input" type="search" placeholder="Search foods" value={query} onChange={(e) => setQuery(e.target.value)} aria-label="Search foods" />
      <div className="chips">
        <button className="chip" aria-pressed={category === null} onClick={() => setCategory(null)}>All</button>
        {CATEGORIES.map((c) => <button key={c} className="chip" aria-pressed={category === c} onClick={() => setCategory(c)}>{c}</button>)}
      </div>
      <button className="btn btn-secondary" onClick={() => setCreating(true)}>＋ Create custom food</button>
      <div className="card">
        {results.length === 0 && <div className="empty">No foods match. Try Text or Voice to have AI estimate it.</div>}
        {results.map((f) => <FoodRow key={f.id} food={f} onPick={() => onPick([foodToItem(f)])} />)}
      </div>
      {creating && <CreateFood onClose={() => setCreating(false)} />}
    </div>
  )
}

function FoodRow({ food, onPick }: { food: FoodItem; onPick: () => void }) {
  return (
    <button className="list-row" onClick={onPick}>
      <span style={{ fontSize: 26 }} aria-hidden="true">{food.emoji}</span>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14 }}>{food.name}{food.isCustom && <span className="tiny faint"> · custom</span>}</div>
        <div className="tiny faint">{food.serving} · P {Math.round(food.protein)} · C {Math.round(food.carbs)} · F {Math.round(food.fat)}</div>
      </div>
      <span className="small muted">{Math.round(food.calories)} cal</span>
    </button>
  )
}
