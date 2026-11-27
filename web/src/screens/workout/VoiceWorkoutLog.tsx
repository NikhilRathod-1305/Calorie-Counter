import { useState } from 'react'
import { db, newId } from '../../lib/db'
import { parseWorkoutAudio, parseWorkoutText } from '../../lib/gemini'
import { loadApiKey } from '../../lib/settings'
import { recordingToWavBase64, startRecording, type Recorder } from '../../lib/audio'
import type { WorkoutSession } from '../../lib/types'
import { applyCommands } from '../../lib/workout'
import { Sheet } from '../../ui/Sheet'
import { ErrorBox, errorMessage, useToast } from '../../ui/controls'
import type { ParsedWorkoutCommand } from '../../lib/gemini'

/** Logs sets by voice or text into the active session (creating one if needed). */
export function VoiceWorkoutLog({ active, onClose, onApplied }: { active: WorkoutSession | null; onClose: () => void; onApplied: (finished: boolean) => void }) {
  const toast = useToast()
  const [text, setText] = useState('')
  const [recorder, setRecorder] = useState<Recorder | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const apply = async (parse: () => Promise<ParsedWorkoutCommand[]>) => {
    setBusy(true); setError(null)
    try {
      const { session, finished, added } = applyCommands(active, await parse(), newId, Date.now())
      await db.workouts.put(session)
      toast(finished ? 'Workout saved' : added ? `Logged ${added} set${added === 1 ? '' : 's'}` : 'Updated')
      onApplied(finished)
    } catch (e) { setError(errorMessage(e)) } finally { setBusy(false) }
  }

  const toggleRecord = async () => {
    if (recorder) {
      setRecorder(null)
      const blob = await recorder.stop()
      void apply(async () => parseWorkoutAudio(loadApiKey(), await recordingToWavBase64(blob)))
      return
    }
    try { setRecorder(await startRecording()) } catch (e) { setError(`Microphone unavailable: ${errorMessage(e)}`) }
  }

  if (!loadApiKey()) {
    return <Sheet title="Log by Voice" onClose={onClose}><div className="info-box">Add your Gemini API key in More → Gemini API Key to log workouts by voice or text.</div></Sheet>
  }

  return (
    <Sheet title="Log by Voice" onClose={() => { recorder?.cancel(); onClose() }}>
      <div className="stack">
        <button className={`record-btn${recorder ? ' on' : ''}`} disabled={busy} onClick={toggleRecord} aria-label={recorder ? 'Stop recording' : 'Start recording'}>{recorder ? '■' : '🎙️'}</button>
        <div className="small muted center">{recorder ? 'Listening… tap to finish' : 'e.g. “bench press 60 kg for 10, three sets” or “ran 5 km in 28 minutes”'}</div>
        <div className="row">
          <input className="input" placeholder="Or type it" value={text} onChange={(e) => setText(e.target.value)} aria-label="Workout command" />
          <button className="btn btn-primary" disabled={busy || !text.trim()} onClick={() => apply(() => parseWorkoutText(loadApiKey(), text.trim()))}>Log</button>
        </div>
        {busy && <div className="spinner" />}
        <ErrorBox message={error} />
      </div>
    </Sheet>
  )
}
