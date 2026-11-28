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
// The ring number counts up; wait until it stops changing before reading it.
await page.waitForFunction(() => {
  const el = document.querySelectorAll('.num')[1]
  const v = el?.textContent
  return new Promise((r) => setTimeout(() => r(el?.textContent === v), 900))
})
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

// Home extras: quick water + undo, activity log + delete, meal delete + undo, swipe-down dismiss
const nav = page.getByRole('navigation', { name: 'Main' })
await nav.getByRole('button', { name: 'Home' }).click()
const fail = (msg) => { throw new Error(msg) }
await page.getByRole('button', { name: 'Add 250 ml water' }).click()
await page.getByText('750 / 2000 ml').waitFor()
await page.getByRole('button', { name: 'Undo' }).click()
await page.getByText('500 / 2000 ml').waitFor()
step('quick water + undo')

await page.getByRole('button', { name: 'Quick log' }).click()
await page.getByRole('button', { name: 'Calories Burned' }).click()
await page.getByLabel('Activity').fill('Badminton')
await page.getByLabel('Calories (kcal)').fill('300')
await page.getByRole('button', { name: 'Save' }).click()
await page.getByText('Badminton').waitFor()
await page.getByText('300 kcal burned', { exact: false }).first().waitFor()
await page.getByRole('button', { name: 'Delete Badminton' }).click()
await page.getByText('Badminton').waitFor({ state: 'detached' })
step('activity listed + deleted')

await page.getByRole('button', { name: /Dal & Roti/ }).click()
await page.getByRole('button', { name: 'Delete', exact: true }).click()
const dalRow = page.getByRole('button', { name: /^Dal & Roti 2 items/ })
await dalRow.waitFor({ state: 'detached' })
await page.getByRole('button', { name: 'Undo' }).click()
await dalRow.waitFor()
step('meal delete + undo')

await page.getByRole('button', { name: 'Water', exact: false }).filter({ hasText: 'Water' }).first().click()
const sheet = page.getByRole('dialog', { name: 'Log Drink' })
await sheet.waitFor()
await page.getByRole('button', { name: /Remove Water at/ }).first().waitFor()
await page.waitForTimeout(500) // let the open animation finish before measuring
const head = await sheet.locator('.sheet-head').boundingBox()
await page.mouse.move(head.x + 40, head.y + 30)
await page.mouse.down()
for (let i = 1; i <= 8; i++) await page.mouse.move(head.x + 40, head.y + 30 + i * 30)
await page.mouse.up()
await sheet.waitFor({ state: 'detached' })
if (!(await nav.isVisible())) fail('tab bar did not come back after closing sheet')
step('drink list + swipe-down dismiss')

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
