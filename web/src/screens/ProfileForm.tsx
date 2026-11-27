import { ACTIVITY_LEVELS, GOAL_TYPES, MACRO_PRESETS, SEXES, computeGoals, type Profile } from '../lib/goals'
import { NumberField, Segmented } from '../ui/controls'

export const PROFILE_LIMITS = { heightCm: [100, 250], age: [13, 100], weightKg: [30, 300], targetWeightKg: [30, 300], weeklyRateKg: [0.1, 1], waterGoalMl: [500, 6000] } as const

export function validateProfile(p: Profile): string | null {
  for (const [key, [lo, hi]] of Object.entries(PROFILE_LIMITS)) {
    const v = p[key as keyof typeof PROFILE_LIMITS]
    if (!(typeof v === 'number' && v >= lo && v <= hi)) return `${LABELS[key as keyof typeof PROFILE_LIMITS]} must be between ${lo} and ${hi}.`
  }
  return null
}

const LABELS: Record<keyof typeof PROFILE_LIMITS, string> = { heightCm: 'Height', age: 'Age', weightKg: 'Weight', targetWeightKg: 'Target weight', weeklyRateKg: 'Weekly rate', waterGoalMl: 'Water goal' }

/** Profile editor shared by onboarding and More → Profile & Goals. Numbers may be NaN mid-edit; validate before saving. */
export function ProfileForm({ value, onChange }: { value: Profile; onChange: (p: Profile) => void }) {
  const set = <K extends keyof Profile>(k: K, v: Profile[K]) => onChange({ ...value, [k]: v })
  const num = (k: keyof typeof PROFILE_LIMITS) => (v: number | undefined) => set(k, v ?? Number.NaN)
  const valid = validateProfile(value) === null
  const goals = valid ? computeGoals(value) : null

  return (
    <div className="stack">
      <div className="field"><span className="field-label">Sex (for the calorie formula)</span><Segmented label="Sex (for the calorie formula)" options={SEXES} value={value.sex} onChange={(v) => set('sex', v)} /></div>
      <div className="grid-3">
        <NumberField label="Age" value={nanToUndef(value.age)} onChange={num('age')} />
        <NumberField label="Height" suffix="cm" value={nanToUndef(value.heightCm)} onChange={num('heightCm')} />
        <NumberField label="Weight" suffix="kg" value={nanToUndef(value.weightKg)} onChange={num('weightKg')} />
      </div>
      <div className="field"><span className="field-label">Activity level</span><Segmented label="Activity level" options={ACTIVITY_LEVELS} value={value.activityLevel} onChange={(v) => set('activityLevel', v)} /></div>
      <div className="field"><span className="field-label">Goal</span><Segmented label="Goal" options={GOAL_TYPES} value={value.goalType} onChange={(v) => set('goalType', v)} labels={{ 'Lose weight': 'Lose', 'Maintain weight': 'Maintain', 'Gain weight': 'Gain' }} /></div>
      <div className="grid-2">
        <NumberField label="Target weight" suffix="kg" value={nanToUndef(value.targetWeightKg)} onChange={num('targetWeightKg')} />
        {value.goalType !== 'Maintain weight' && <NumberField label="Rate per week" suffix="kg" value={nanToUndef(value.weeklyRateKg)} onChange={num('weeklyRateKg')} step="0.1" />}
      </div>
      <div className="field"><span className="field-label">Macro split</span><Segmented label="Macro split" options={MACRO_PRESETS} value={value.macroPreset} onChange={(v) => set('macroPreset', v)} /></div>
      <NumberField label="Daily water goal" suffix="ml" value={nanToUndef(value.waterGoalMl)} onChange={num('waterGoalMl')} />
      {goals && (
        <div className="info-box">
          Daily goal: <b>{goals.calorieGoal} kcal</b> · Protein {goals.proteinG}g · Carbs {goals.carbG}g · Fat {goals.fatG}g
        </div>
      )}
    </div>
  )
}

const nanToUndef = (v: number) => (Number.isNaN(v) ? undefined : v)
