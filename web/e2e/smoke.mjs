// Drives the production build in local Chrome (iPhone-sized viewport) through the core flows.
// Usage: npm run build && npx vite preview --port 4173 & node e2e/smoke.mjs
import { chromium } from 'playwright-core'

const URL = process.env.APP_URL ?? 'http://localhost:4173/'
const SHOTS = process.env.SHOT_DIR
const browser = await chromium.launch({ channel: 'chrome', headless: true })
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 })
const errors = []
page.on('pageerror', (e) => errors.push(e.message))
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()) })
const shot = async (name) => { if (SHOTS) await page.screenshot({ path: `${SHOTS}/${name}.png` }) }
const step = (name) => console.log('✓', name)

// Gemini is mocked so AI flows run offline and deterministically.
await page.route('https://generativelanguage.googleapis.com/**', (route) => {
  const body = route.request().postDataJSON()
  const fn = body.tools[0].functionDeclarations[0].name
  const args = fn === 'log_food'
    ? { items: [{ name: 'Dal', calories: 230, protein_g: 12, carbs_g: 30, fat_g: 6, fiber_g: 8, sugar_g: 2, sodium_mg: 400 }, { name: 'Roti', calories: 104, protein_g: 3, carbs_g: 20, fat_g: 1, fiber_g: 2, sugar_g: 0, sodium_mg: 100 }] }
    : { commands: [{ action: 'log_set', exercise_name: 'Bench Press', sets: 3, reps: 10, weight_kg: 60 }] }
  route.fulfill({ json: { candidates: [{ content: { parts: [{ functionCall: { name: fn, args } }] } }] } })
})

await page.goto(URL)
await page.getByRole('button', { name: 'Get started' }).click()
await page.getByLabel(/Age/).fill('28')
await page.getByRole('button', { name: 'Male', exact: true }).click()
await shot('01-onboarding')
await page.getByRole('button', { name: 'Continue' }).click()
await page.getByLabel('Gemini API key').fill('test-key')
await page.getByRole('button', { name: 'Finish' }).click()
await page.getByRole('navigation', { name: 'Main' }).waitFor()
step('onboarding')

// Browse library food into Breakfast
await page.getByRole('button', { name: 'Add to Breakfast' }).click()
await page.getByLabel('Search foods').fill('banana')
await page.getByRole('button', { name: /Banana/ }).first().click()
await page.getByRole('button', { name: 'Increase' }).click()
await page.getByRole('button', { name: 'Add to Diary' }).click()
await page.getByText('Banana').first().waitFor()
step('browse + log food')

// AI text logging (multi-item) via quick log
await page.getByRole('button', { name: 'Quick log' }).click()
await page.getByRole('button', { name: 'Log Food' }).click()
await page.getByRole('button', { name: 'Text', exact: true }).click()
await page.getByLabel('Describe what you ate').fill('dal and a roti')
await page.getByRole('button', { name: 'Estimate with AI' }).click()
await page.getByRole('button', { name: 'Remove Roti' }).waitFor()
await shot('02-review')
await page.getByRole('button', { name: 'Add to Diary' }).click()
await page.getByText('Dal & Roti').waitFor()
const remaining = await page.locator('.num').nth(1).textContent()
await shot('03-home')
step(`AI text log (ring shows ${remaining})`)

// Water
await page.getByRole('button', { name: 'Quick log' }).click()
await page.getByRole('button', { name: 'Water', exact: true }).click()
await page.getByRole('button', { name: '500 ml' }).click()
await page.getByRole('button', { name: 'Add 500 ml' }).click()
await page.getByRole('navigation', { name: 'Main' }).getByRole('button', { name: 'Tracker' }).click()
await page.getByText('500', { exact: false }).first().waitFor()
await shot('04-tracker')
step('water + tracker')

// Workout: start from routine, log by text, finish
await page.getByRole('navigation', { name: 'Main' }).getByRole('button', { name: 'Workout' }).click()
await page.getByRole('button', { name: 'Start', exact: true }).first().click()
await page.getByRole('button', { name: /Mark set 1 done/ }).first().click()
await page.getByRole('button', { name: /Voice \/ Text/ }).click()
await page.getByLabel('Workout command').fill('bench 60kg 3x10')
await page.getByRole('button', { name: 'Log', exact: true }).click()
await page.getByRole('dialog', { name: 'Log by Voice' }).waitFor({ state: 'detached' })
await shot('05-active-workout')
page.once('dialog', (d) => d.accept())
await page.getByRole('button', { name: 'Finish' }).click()
await page.getByText(/sets · /).first().waitFor()
step('workout routine + text log + finish')

// Reload: data persists in IndexedDB
await page.reload()
await page.getByText('Dal & Roti').waitFor()
step('persists across reload')

// Dark mode
await page.getByRole('navigation', { name: 'Main' }).getByRole('button', { name: 'More' }).click()
await page.getByRole('button', { name: 'Dark', exact: true }).click()
await page.getByRole('navigation', { name: 'Main' }).getByRole('button', { name: 'Home' }).click()
await shot('06-home-dark')
step('dark mode')

const swReady = await page.evaluate(async () => !!(await navigator.serviceWorker.ready))
step(`service worker ready: ${swReady}`)

await browser.close()
if (errors.length) { console.error('Page errors:\n' + errors.join('\n')); process.exit(1) }
console.log('ALL FLOWS PASSED')
