// Visual tour: screenshots every screen and sheet at iPhone size with simulated notch/home-indicator insets.
// Usage: npm run build && npx vite preview --port 4173 & SHOT_DIR=/tmp/shots node e2e/screens.mjs
import { chromium } from 'playwright-core'

const URL = process.env.APP_URL ?? 'http://localhost:4173/'
const DIR = process.env.SHOT_DIR ?? '.'
const THEME = process.env.THEME ?? 'light'
const W = Number(process.env.W ?? 390), H = Number(process.env.H ?? 844)
const browser = await chromium.launch({ channel: 'chrome', headless: true })
const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2, colorScheme: THEME })
const errors = []
page.on('pageerror', (e) => errors.push(e.message))
// Chrome has no notch: fake the iPhone safe-area insets.
const INSETS = ':root{--safe-top:47px!important;--safe-bottom:34px!important}'
await page.addInitScript((css) => {
  document.addEventListener('DOMContentLoaded', () => { const s = document.createElement('style'); s.textContent = css; document.head.append(s) })
}, INSETS)
await page.route('https://generativelanguage.googleapis.com/**', (route) => {
  const fn = route.request().postDataJSON().tools[0].functionDeclarations[0].name
  const args = fn === 'log_food'
    ? { items: [{ name: 'Dal', calories: 230, protein_g: 12, carbs_g: 30, fat_g: 6, fiber_g: 8, sugar_g: 2, sodium_mg: 400 }, { name: 'Roti', calories: 104, protein_g: 3, carbs_g: 20, fat_g: 1, fiber_g: 2, sugar_g: 0, sodium_mg: 100 }] }
    : { commands: [{ action: 'log_set', exercise_name: 'Bench Press', sets: 3, reps: 10, weight_kg: 60 }] }
  route.fulfill({ json: { candidates: [{ content: { parts: [{ functionCall: { name: fn, args } }] } }] } })
})
let n = 0
const shot = async (name, full = false) => { await page.waitForTimeout(350); await page.screenshot({ path: `${DIR}/${String(++n).padStart(2, '0')}-${name}.png`, fullPage: full }) }
const click = (role, name, exact = true) => page.getByRole(role, { name, exact }).first().click()
const close = () => page.getByRole('button', { name: 'Close' }).last().click()
const nav = (name) => page.getByRole('navigation', { name: 'Main' }).getByRole('button', { name }).click()

await page.goto(URL)
await shot('welcome')
await click('button', 'Get started')
await page.getByLabel(/Age/).fill('28')
await shot('onboarding-profile')
await click('button', 'Continue')
await shot('onboarding-key')
await page.getByLabel('Gemini API key').fill('test-key')
await click('button', 'Finish')
await page.getByRole('navigation', { name: 'Main' }).waitFor()
await shot('home-empty')

await click('button', 'Add to Breakfast')
await shot('logfood-browse')
await page.getByLabel('Search foods').fill('banana')
await page.getByRole('button', { name: /Banana/ }).first().click()
await shot('food-detail')
await click('button', 'Add to Diary')
await click('button', 'Quick log')
await shot('quicklog')
await click('button', 'Log Food')
await click('button', 'Text')
await shot('logfood-text')
await page.getByLabel('Describe what you ate').fill('dal and roti')
await click('button', 'Estimate with AI')
await page.getByRole('button', { name: 'Remove Roti' }).waitFor()
await shot('review')
await click('button', 'Add to Diary')
await page.waitForTimeout(300)
await shot('home-filled')
await shot('home-filled-full', true)
await page.getByRole('button', { name: /Dal & Roti/ }).click()
await shot('edit-entry')
await close()

await click('button', 'Quick log')
await click('button', 'Voice Log')
await shot('logfood-voice')
await click('button', 'Photo')
await shot('logfood-photo')
await click('button', 'Barcode')
await page.waitForTimeout(800)
await shot('logfood-barcode')
await close(); await close()
await click('button', 'Quick log')
await click('button', 'Water')
await shot('water')
await click('button', '500 ml')
await click('button', 'Add 500 ml')
await click('button', 'Quick log')
await click('button', 'Calories Burned')
await shot('exercise')
await close(); await close()

await nav('Tracker')
await shot('tracker')
await shot('tracker-full', true)
await nav('Workout')
await shot('workout')
await click('button', 'Start')
await shot('active-workout')
await shot('active-workout-full', true)
await click('button', '＋ Exercise')
await shot('exercise-picker')
await close()
await click('button', 'Voice / Text', false)
await shot('voice-workout')
await close()
page.once('dialog', (d) => d.accept())
await click('button', 'Finish')
await page.waitForTimeout(400)
await shot('workout-history')
await page.getByRole('button', { name: /sets · / }).first().click()
await shot('session-detail')
await close()
await page.getByRole('button', { name: /Push/ }).first().click()
await shot('routine-builder')
await close()

await nav('More')
await shot('more')
await click('button', 'Profile & Goals', false)
await shot('profile')
await close()
await click('button', 'Install on iPhone', false)
await shot('install')
await close()

console.log(errors.length ? `ERRORS: ${errors.join(' | ')}` : 'no page errors')
await browser.close()
