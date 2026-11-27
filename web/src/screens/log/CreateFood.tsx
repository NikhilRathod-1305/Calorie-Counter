import { useState } from 'react'
import { db, newId } from '../../lib/db'
import { Sheet } from '../../ui/Sheet'
import { ErrorBox, NumberField, errorMessage, useToast } from '../../ui/controls'

type Num = number | undefined
const FIELDS = [['calories', 'Calories', 'kcal'], ['protein', 'Protein', 'g'], ['carbs', 'Carbs', 'g'], ['fat', 'Fat', 'g'], ['fiber', 'Fiber', 'g'], ['sugar', 'Sugar', 'g'], ['sodium', 'Sodium', 'mg']] as const

export function CreateFood({ onClose }: { onClose: () => void }) {
  const toast = useToast()
  const [name, setName] = useState('')
  const [serving, setServing] = useState('1 serving')
  const [servingSize, setServingSize] = useState<Num>(100)
  const [unit, setUnit] = useState('g')
  const [values, setValues] = useState<Record<string, Num>>({})
  const [error, setError] = useState<string | null>(null)

  const save = async () => {
    if (!name.trim()) return setError('Give the food a name.')
    if (values.calories === undefined || values.calories < 0) return setError('Enter the calories per serving.')
    if (!servingSize || servingSize <= 0) return setError('Serving size must be greater than 0.')
    try {
      const v = (k: string) => Math.max(0, values[k] ?? 0)
      await db.customFoods.add({
        id: newId(), name: name.trim(), brand: null, serving: serving.trim() || `${servingSize}${unit}`, servingSize, servingUnit: unit,
        calories: v('calories'), protein: v('protein'), carbs: v('carbs'), fat: v('fat'), fiber: v('fiber'), sugar: v('sugar'), sodium: v('sodium'),
        category: 'Other', emoji: '🍽️', isCustom: true,
      })
      toast('Food created')
      onClose()
    } catch (e) { setError(errorMessage(e)) }
  }

  return (
    <Sheet title="Create Food" onClose={onClose}>
      <div className="stack">
        <label className="field"><span className="field-label">Name</span><input className="input" value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Mom's dal" /></label>
        <div className="grid-3">
          <label className="field"><span className="field-label">Serving</span><input className="input" value={serving} onChange={(e) => setServing(e.target.value)} /></label>
          <NumberField label="Size" value={servingSize} onChange={setServingSize} />
          <label className="field"><span className="field-label">Unit</span><select className="input" value={unit} onChange={(e) => setUnit(e.target.value)}><option>g</option><option>ml</option></select></label>
        </div>
        <div className="grid-2">
          {FIELDS.map(([k, label, u]) => <NumberField key={k} label={label} suffix={u} value={values[k]} onChange={(v) => setValues((prev) => ({ ...prev, [k]: v }))} />)}
        </div>
        <ErrorBox message={error} />
        <button className="btn btn-primary btn-block" onClick={save}>Save Food</button>
      </div>
    </Sheet>
  )
}
