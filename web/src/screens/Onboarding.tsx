import { useState } from 'react'
import { db, newId, saveProfile } from '../lib/db'
import { defaultProfile, type Profile } from '../lib/goals'
import { saveApiKey } from '../lib/settings'
import { ErrorBox, errorMessage } from '../ui/controls'
import { ProfileForm, validateProfile } from './ProfileForm'

export function Onboarding() {
  const [step, setStep] = useState<0 | 1 | 2>(0)
  const [profile, setProfile] = useState<Profile>({ ...defaultProfile })
  const [key, setKey] = useState('')
  const [error, setError] = useState<string | null>(null)

  const next = () => {
    const problem = validateProfile(profile)
    if (problem) return setError(problem)
    setError(null); setStep(2)
  }
  const finish = async () => {
    try {
      saveApiKey(key)
      await db.weights.add({ id: newId(), timestamp: Date.now(), kg: profile.weightKg })
      await saveProfile({ ...profile, hasCompletedOnboarding: true })
    } catch (e) { setError(errorMessage(e)) }
  }

  return (
    <div className="screen" style={{ paddingBottom: 'calc(var(--safe-bottom) + 24px)' }}>
      {step === 0 && (
        <div className="stack center" style={{ paddingTop: 40 }}>
          <img src={`${import.meta.env.BASE_URL}icon-192.png`} alt="" width={96} height={96} style={{ borderRadius: 22, margin: '0 auto' }} />
          <h1 style={{ fontSize: 32 }}>Count on Me</h1>
          <p className="muted">Track food, water, weight and workouts. Log meals by photo, voice or barcode.</p>
          <div className="card card-pad" style={{ textAlign: 'left' }}>
            <div className="small">🔒 Your data stays on this device. Nothing is uploaded except the photos, voice clips or text you send to Gemini for estimates.</div>
          </div>
          <button className="btn btn-primary btn-block" onClick={() => setStep(1)}>Get started</button>
        </div>
      )}
      {step === 1 && (
        <div className="stack">
          <h1 className="screen-title">About you</h1>
          <ProfileForm value={profile} onChange={setProfile} />
          <ErrorBox message={error} />
          <button className="btn btn-primary btn-block" onClick={next}>Continue</button>
        </div>
      )}
      {step === 2 && (
        <div className="stack">
          <h1 className="screen-title">AI logging (optional)</h1>
          <p className="muted">Photo, voice and text logging use Google Gemini with your own free API key. Create one at <b>aistudio.google.com/apikey</b> and paste it below. You can also add it later in More.</p>
          <input className="input" placeholder="Gemini API key" value={key} onChange={(e) => setKey(e.target.value)} autoComplete="off" spellCheck={false} aria-label="Gemini API key" />
          <ErrorBox message={error} />
          <button className="btn btn-primary btn-block" onClick={finish}>{key.trim() ? 'Finish' : 'Skip for now'}</button>
          <button className="btn btn-secondary" onClick={() => setStep(1)}>Back</button>
        </div>
      )}
    </div>
  )
}
