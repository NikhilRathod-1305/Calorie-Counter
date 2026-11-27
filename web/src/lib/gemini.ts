import type { Nutrition } from './nutrition'

export const MODEL_FALLBACKS = ['gemini-3.6-flash', 'gemini-flash-latest', 'gemini-2.5-flash'] as const
const ENDPOINT = (model: string) => `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`
const RETRY_BACKOFF_MS = 1500
const RETRYABLE_STATUSES = new Set([404, 429, 503])

export class GeminiError extends Error {
  readonly status?: number
  constructor(message: string, status?: number) {
    super(message)
    this.name = 'GeminiError'
    this.status = status
  }
}

interface CallOptions {
  fetchImpl?: typeof fetch
  sleep?: (ms: number) => Promise<void>
}

const defaultSleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms))

/**
 * POSTs to Gemini, trying each fallback model. 404 (retired model) and 429/503
 * (overloaded) move to the next model; the whole list is retried once after a
 * short backoff. Any other failure is surfaced immediately.
 */
export async function callGemini(apiKey: string, body: unknown, opts: CallOptions = {}): Promise<unknown> {
  if (!apiKey.trim()) throw new GeminiError('Add your Gemini API key in More → Settings to use AI logging.')
  const fetchImpl = opts.fetchImpl ?? fetch
  const sleep = opts.sleep ?? defaultSleep
  let lastError = new GeminiError("Gemini couldn't parse a response. Try again.")

  for (let attempt = 0; attempt < 2; attempt++) {
    for (const model of MODEL_FALLBACKS) {
      let res: Response
      try {
        res = await fetchImpl(ENDPOINT(model), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey.trim() },
          body: JSON.stringify(body),
        })
      } catch (e) {
        throw new GeminiError(`Network error: ${e instanceof Error ? e.message : String(e)}. Check your connection.`)
      }
      if (res.ok) return res.json()
      const text = (await res.text()).slice(0, 200)
      lastError = new GeminiError(
        res.status === 429 || res.status === 503
          ? 'Gemini is temporarily overloaded. Please try again in a moment.'
          : `Gemini error (status ${res.status}): ${text}`,
        res.status,
      )
      if (!RETRYABLE_STATUSES.has(res.status)) throw lastError
    }
    if (attempt === 0) await sleep(RETRY_BACKOFF_MS)
  }
  throw lastError
}

/** Returns the args of the first functionCall part in a Gemini response. */
function functionArgs(json: unknown): Record<string, unknown> | null {
  const parts = (json as { candidates?: { content?: { parts?: unknown[] } }[] })?.candidates?.[0]?.content?.parts
  if (!Array.isArray(parts)) throw new GeminiError("Gemini couldn't parse a response. Try again.")
  for (const part of parts) {
    const args = (part as { functionCall?: { args?: unknown } })?.functionCall?.args
    if (args && typeof args === 'object') return args as Record<string, unknown>
  }
  return null
}

const num = (v: unknown): number => (typeof v === 'number' && Number.isFinite(v) ? v : Number(v) || 0)
const optNum = (v: unknown): number | undefined => (v === undefined || v === null || Number.isNaN(Number(v)) ? undefined : Number(v))

// ---------- Food ----------

export interface ParsedFood {
  name: string
  nutrition: Nutrition
}

const LOG_FOOD = {
  name: 'log_food',
  description: 'Report every distinct food or drink item identified, each with its own nutritional values for the portion described or shown.',
  parameters: {
    type: 'object',
    properties: {
      items: {
        type: 'array',
        description: 'One entry per distinct food/drink item. If only one food is present, return a single-element array.',
        items: {
          type: 'object',
          properties: {
            name: { type: 'string', description: 'Short, natural name of the food item.' },
            calories: { type: 'number' },
            protein_g: { type: 'number' },
            carbs_g: { type: 'number' },
            fat_g: { type: 'number' },
            fiber_g: { type: 'number' },
            sugar_g: { type: 'number' },
            sodium_mg: { type: 'number' },
          },
          required: ['name', 'calories', 'protein_g', 'carbs_g', 'fat_g', 'fiber_g', 'sugar_g', 'sodium_mg'],
        },
      },
    },
    required: ['items'],
  },
}

const FOOD_SYSTEM = 'You are a nutrition estimation assistant. Always call the log_food function exactly once with your best estimate, listing each distinct food or drink as a separate item in the items array rather than merging them into one combined item. Never ask clarifying questions.'

type Part = { text: string } | { inline_data: { mime_type: string; data: string } }

function forcedCallBody(system: string, fn: { name: string }, parts: Part[]) {
  return {
    contents: [{ role: 'user', parts }],
    systemInstruction: { parts: [{ text: system }] },
    tools: [{ functionDeclarations: [fn] }],
    toolConfig: { functionCallingConfig: { mode: 'ANY', allowedFunctionNames: [fn.name] } },
  }
}

export function parseFoodItems(json: unknown): ParsedFood[] {
  const args = functionArgs(json)
  const items = args?.items
  if (!Array.isArray(items) || items.length === 0) throw new GeminiError("Couldn't identify that food. Try again or use Browse.")
  return items.map((raw) => {
    const i = raw as Record<string, unknown>
    return {
      name: typeof i.name === 'string' && i.name.trim() ? i.name.trim() : 'Meal',
      nutrition: {
        calories: num(i.calories), protein: num(i.protein_g), carbs: num(i.carbs_g), fat: num(i.fat_g),
        fiber: num(i.fiber_g), sugar: num(i.sugar_g), sodium: num(i.sodium_mg),
      },
    }
  })
}

const correction = (refinement?: string, against = 'the description above') =>
  refinement?.trim() ? ` Correction from the user, which takes priority over ${against}: "${refinement.trim()}"` : ''

export async function parseFoodText(apiKey: string, description: string, refinement?: string): Promise<ParsedFood[]> {
  const prompt = `Estimate the nutrition for this food/meal description, using reasonable standard portions when not specified. If it describes more than one distinct food or drink, list each as a separate item rather than combining them: "${description}"${correction(refinement)}`
  return parseFoodItems(await callGemini(apiKey, forcedCallBody(FOOD_SYSTEM, LOG_FOOD, [{ text: prompt }])))
}

export async function parseFoodImage(apiKey: string, jpegBase64: string, refinement?: string): Promise<ParsedFood[]> {
  const prompt = `Identify each distinct food or drink in this photo and estimate its nutrition based on the portion shown. If there are multiple separate items on the plate (e.g. eggs, toast, juice), list each as its own item rather than combining them into one total.${correction(refinement, 'what the photo appears to show')}`
  return parseFoodItems(await callGemini(apiKey, forcedCallBody(FOOD_SYSTEM, LOG_FOOD, [
    { inline_data: { mime_type: 'image/jpeg', data: jpegBase64 } },
    { text: prompt },
  ])))
}

export async function parseFoodAudio(apiKey: string, wavBase64: string): Promise<ParsedFood[]> {
  const prompt = 'This audio is someone saying what they ate or drank. Listen to it and estimate the nutrition, using reasonable standard portions when not specified. If they mention more than one distinct food or drink, list each as a separate item.'
  return parseFoodItems(await callGemini(apiKey, forcedCallBody(FOOD_SYSTEM, LOG_FOOD, [
    { inline_data: { mime_type: 'audio/wav', data: wavBase64 } },
    { text: prompt },
  ])))
}

export async function refineFood(apiKey: string, items: readonly ParsedFood[], refinement: string): Promise<ParsedFood[]> {
  const lines = items.map((i) => `- ${i.name}: ${Math.round(i.nutrition.calories)} cal, ${Math.round(i.nutrition.protein)}g protein, ${Math.round(i.nutrition.carbs)}g carbs, ${Math.round(i.nutrition.fat)}g fat`).join('\n')
  const prompt = `Here is the current list of food items logged for a meal:\n${lines}\n\nApply this correction from the user and return the corrected, complete item list (including any items that don't need changes): "${refinement}"`
  return parseFoodItems(await callGemini(apiKey, forcedCallBody(FOOD_SYSTEM, LOG_FOOD, [{ text: prompt }])))
}

// ---------- Workout ----------

export type WorkoutAction = 'log_set' | 'start_workout' | 'finish_workout'
const WORKOUT_ACTIONS = new Set<WorkoutAction>(['log_set', 'start_workout', 'finish_workout'])

export interface ParsedWorkoutCommand {
  action: WorkoutAction
  exerciseName?: string
  sets?: number
  reps?: number
  weightKg?: number
  durationMinutes?: number
  distanceKm?: number
  workoutName?: string
}

const LOG_WORKOUT = {
  name: 'log_workout',
  description: 'Interpret a spoken or typed workout command as one or more structured actions.',
  parameters: {
    type: 'object',
    properties: {
      commands: {
        type: 'array',
        description: "One entry per distinct exercise/action described. If the user lists multiple exercises in one command (e.g. 'bench press 60kg for 10, then squats 3 sets of 8, then plank for 2 minutes'), return one log_set entry per exercise rather than combining them.",
        items: {
          type: 'object',
          properties: {
            action: { type: 'string', enum: ['log_set', 'start_workout', 'finish_workout'], description: 'log_set: logging one or more sets of an exercise (strength or cardio). start_workout: beginning a new workout, optionally named/routine-based. finish_workout: ending the current workout.' },
            exercise_name: { type: 'string', description: "Name of the exercise, e.g. 'Bench Press', 'Running'. Required for log_set." },
            sets: { type: 'integer', description: "Number of sets described, e.g. 'three sets of squats' = 3. Default 1." },
            reps: { type: 'integer', description: 'Reps per set, for strength exercises.' },
            weight_kg: { type: 'number', description: 'Weight in kilograms per set. Convert from pounds if the user said lbs (1 lb = 0.453592 kg).' },
            duration_minutes: { type: 'number', description: 'Duration in minutes, for cardio exercises.' },
            distance_km: { type: 'number', description: 'Distance in kilometers, for cardio exercises. Convert from miles if needed (1 mile = 1.60934 km).' },
            workout_name: { type: 'string', description: "Name of the workout being started, e.g. 'push', 'leg day'. Only for start_workout." },
          },
          required: ['action'],
        },
      },
    },
    required: ['commands'],
  },
}

const WORKOUT_SYSTEM = 'You are a workout logging assistant. Always call the log_workout function exactly once with your best interpretation of the command, listing one entry in the commands array per distinct exercise or action described. Never ask clarifying questions.'

export function parseWorkoutCommands(json: unknown): ParsedWorkoutCommand[] {
  const commands = functionArgs(json)?.commands
  if (!Array.isArray(commands)) throw new GeminiError("Couldn't understand that command. Try again or log manually.")
  const parsed = commands.flatMap((raw): ParsedWorkoutCommand[] => {
    const c = raw as Record<string, unknown>
    if (!WORKOUT_ACTIONS.has(c.action as WorkoutAction)) return []
    const cmd: ParsedWorkoutCommand = {
      action: c.action as WorkoutAction,
      exerciseName: typeof c.exercise_name === 'string' ? c.exercise_name : undefined,
      sets: optNum(c.sets),
      reps: optNum(c.reps),
      weightKg: optNum(c.weight_kg),
      durationMinutes: optNum(c.duration_minutes),
      distanceKm: optNum(c.distance_km),
      workoutName: typeof c.workout_name === 'string' ? c.workout_name : undefined,
    }
    return [Object.fromEntries(Object.entries(cmd).filter(([, v]) => v !== undefined)) as unknown as ParsedWorkoutCommand]
  })
  if (parsed.length === 0) throw new GeminiError("Couldn't understand that command. Try again or log manually.")
  return parsed
}

export async function parseWorkoutText(apiKey: string, text: string): Promise<ParsedWorkoutCommand[]> {
  const prompt = `Interpret this workout logging command and call log_workout with the best structured interpretation. If it describes more than one exercise, return a separate command for each rather than combining them: "${text}"`
  return parseWorkoutCommands(await callGemini(apiKey, forcedCallBody(WORKOUT_SYSTEM, LOG_WORKOUT, [{ text: prompt }])))
}

export async function parseWorkoutAudio(apiKey: string, wavBase64: string): Promise<ParsedWorkoutCommand[]> {
  const prompt = 'This audio is a spoken workout logging command. Listen to it and call log_workout with the best structured interpretation. If it describes more than one exercise, return a separate command for each.'
  return parseWorkoutCommands(await callGemini(apiKey, forcedCallBody(WORKOUT_SYSTEM, LOG_WORKOUT, [
    { inline_data: { mime_type: 'audio/wav', data: wavBase64 } },
    { text: prompt },
  ])))
}
