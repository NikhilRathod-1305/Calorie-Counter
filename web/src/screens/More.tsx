import { useEffect, useRef, useState } from 'react'
import { db, exportAll, importBackup, newId, saveProfile } from '../lib/db'
import { parseIosExportCsv } from '../lib/csvImport'
import { loadApiKey, saveApiKey } from '../lib/settings'
import type { Appearance, Profile } from '../lib/goals'
import { useProfile } from '../hooks'
import { Sheet } from '../ui/Sheet'
import { ErrorBox, Segmented, errorMessage, useToast } from '../ui/controls'
import { ProfileForm, validateProfile } from './ProfileForm'

type Panel = 'profile' | 'key' | 'install' | null

export function More() {
  const { profile, goals } = useProfile()
  const toast = useToast()
  const [panel, setPanel] = useState<Panel>(null)
  const [error, setError] = useState<string | null>(null)
  const [persisted, setPersisted] = useState<boolean | null>(null)
  const backupInput = useRef<HTMLInputElement>(null)
  const csvInput = useRef<HTMLInputElement>(null)

  useEffect(() => { void navigator.storage?.persisted?.().then(setPersisted) }, [])

  const download = async () => {
    try {
      const blob = new Blob([await exportAll()], { type: 'application/json' })
      const name = `CountOnMe-Backup-${new Date().toISOString().slice(0, 10)}.json`
      const file = new File([blob], name, { type: 'application/json' })
      if (navigator.canShare?.({ files: [file] })) await navigator.share({ files: [file], title: name })
      else {
        const a = document.createElement('a')
        a.href = URL.createObjectURL(blob); a.download = name; a.click()
        setTimeout(() => URL.revokeObjectURL(a.href), 1000)
      }
    } catch (e) { if ((e as Error).name !== 'AbortError') setError(errorMessage(e)) }
  }

  const restore = async (file: File) => {
    setError(null)
    try { const n = await importBackup(await file.text()); toast(`Restored ${n} records`) } catch (e) { setError(errorMessage(e)) }
  }

  const importCsv = async (file: File) => {
    setError(null)
    try {
      const data = parseIosExportCsv(await file.text())
      const withIds = <T,>(rows: T[]) => rows.map((r) => ({ ...r, id: newId() }))
      await db.transaction('rw', [db.meals, db.exercise, db.weights, db.water], async () => {
        await db.meals.bulkAdd(withIds(data.meals))
        await db.exercise.bulkAdd(withIds(data.exercise))
        await db.weights.bulkAdd(withIds(data.weights))
        await db.water.bulkAdd(withIds(data.water))
      })
      toast(`Imported ${data.meals.length} meals, ${data.weights.length} weights, ${data.water.length} drinks`)
    } catch (e) { setError(errorMessage(e)) }
  }

  const setAppearance = (appearance: Appearance) => void saveProfile({ ...profile, appearance })

  const row = (emoji: string, label: string, detail: string, onClick: () => void) => (
    <button className="list-row" onClick={onClick}>
      <span style={{ fontSize: 20, width: 28, textAlign: 'center' }} aria-hidden="true">{emoji}</span>
      <span style={{ flex: 1 }}>{label}</span><span className="small muted">{detail}</span><span className="faint">›</span>
    </button>
  )

  return (
    <div className="screen">
      <h1 className="screen-title">More</h1>
      <div className="stack">
        <div className="card">
          {row('👤', 'Profile & Goals', `${goals.calorieGoal} kcal`, () => setPanel('profile'))}
          {row('✨', 'Gemini API Key', loadApiKey() ? 'Set' : 'Not set', () => setPanel('key'))}
          {row('📲', 'Install on iPhone', '', () => setPanel('install'))}
        </div>

        <div className="section-label">Appearance</div>
        <Segmented options={['System', 'Light', 'Dark'] as const} value={profile.appearance} onChange={setAppearance} />

        <div className="section-label">Your data</div>
        <div className="card">
          {row('⬇️', 'Back up data', 'JSON', download)}
          {row('⬆️', 'Restore backup', '', () => backupInput.current?.click())}
          {row('📥', 'Import from iOS app', 'CSV', () => csvInput.current?.click())}
        </div>
        <input ref={backupInput} type="file" accept="application/json,.json" hidden onChange={(e) => { const f = e.target.files?.[0]; if (f) void restore(f); e.target.value = '' }} />
        <input ref={csvInput} type="file" accept="text/csv,.csv" hidden onChange={(e) => { const f = e.target.files?.[0]; if (f) void importCsv(f); e.target.value = '' }} />
        <ErrorBox message={error} />
        <div className="tiny faint" style={{ padding: '0 4px' }}>
          Data lives only in this browser on this device{persisted === true ? ' and is protected from automatic cleanup' : ''}. Back up now and then. If you delete the Home Screen app, its data is deleted too.
          {' '}To move data from the old app, use More → Export Data (CSV) there, save it to Files, then tap “Import from iOS app” here.
        </div>
      </div>
      {panel === 'profile' && <EditProfile profile={profile} onClose={() => setPanel(null)} />}
      {panel === 'key' && <ApiKeySheet onClose={() => setPanel(null)} />}
      {panel === 'install' && <InstallHelp onClose={() => setPanel(null)} />}
    </div>
  )
}

function EditProfile({ profile, onClose }: { profile: Profile; onClose: () => void }) {
  const toast = useToast()
  const [draft, setDraft] = useState(profile)
  const [error, setError] = useState<string | null>(null)
  const save = async () => {
    const problem = validateProfile(draft)
    if (problem) return setError(problem)
    try { await saveProfile(draft); toast('Goals updated'); onClose() } catch (e) { setError(errorMessage(e)) }
  }
  return (
    <Sheet title="Profile & Goals" onClose={onClose} full>
      <div className="stack">
        <ProfileForm value={draft} onChange={setDraft} />
        <ErrorBox message={error} />
        <button className="btn btn-primary btn-block" onClick={save}>Save</button>
      </div>
    </Sheet>
  )
}

function ApiKeySheet({ onClose }: { onClose: () => void }) {
  const toast = useToast()
  const [key, setKey] = useState(loadApiKey())
  return (
    <Sheet title="Gemini API Key" onClose={onClose}>
      <div className="stack">
        <p className="small muted" style={{ margin: 0 }}>Used for photo, voice and text logging. Get a free key at <b>aistudio.google.com/apikey</b>. It's stored only on this device and sent only to Google's Gemini API.</p>
        <input className="input" value={key} onChange={(e) => setKey(e.target.value)} placeholder="Paste your key" autoComplete="off" spellCheck={false} aria-label="Gemini API key" />
        <button className="btn btn-primary btn-block" onClick={() => { saveApiKey(key); toast(key.trim() ? 'Key saved' : 'Key removed'); onClose() }}>Save</button>
      </div>
    </Sheet>
  )
}

function InstallHelp({ onClose }: { onClose: () => void }) {
  const standalone = window.matchMedia('(display-mode: standalone)').matches
  return (
    <Sheet title="Install on iPhone" onClose={onClose}>
      <div className="stack small">
        {standalone ? <div className="info-box">✅ You're using the installed app.</div> : null}
        <ol style={{ margin: 0, paddingLeft: 20, lineHeight: 1.7 }}>
          <li>Open this page in <b>Safari</b>.</li>
          <li>Tap the <b>Share</b> button (square with an arrow).</li>
          <li>Choose <b>Add to Home Screen</b>, then <b>Add</b>.</li>
          <li>Open <b>Count on Me</b> from your Home Screen. It runs full-screen, works offline, and never expires.</li>
        </ol>
        <div className="muted">Data saved in Safari and data in the Home Screen app are separate. Start using the Home Screen app, or move data with Back up / Restore.</div>
      </div>
    </Sheet>
  )
}
