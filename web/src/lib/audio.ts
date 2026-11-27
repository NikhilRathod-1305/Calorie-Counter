const TARGET_SAMPLE_RATE = 16000
export const MAX_RECORDING_SECONDS = 60

/** 16-bit mono PCM WAV — a format Gemini accepts regardless of what the browser recorded. */
export function encodeWav(samples: Float32Array, sampleRate: number): ArrayBuffer {
  const buffer = new ArrayBuffer(44 + samples.length * 2)
  const view = new DataView(buffer)
  const write = (offset: number, s: string) => { for (let i = 0; i < s.length; i++) view.setUint8(offset + i, s.charCodeAt(i)) }
  write(0, 'RIFF'); view.setUint32(4, 36 + samples.length * 2, true); write(8, 'WAVE')
  write(12, 'fmt '); view.setUint32(16, 16, true); view.setUint16(20, 1, true); view.setUint16(22, 1, true)
  view.setUint32(24, sampleRate, true); view.setUint32(28, sampleRate * 2, true); view.setUint16(32, 2, true); view.setUint16(34, 16, true)
  write(36, 'data'); view.setUint32(40, samples.length * 2, true)
  samples.forEach((v, i) => {
    const s = Math.max(-1, Math.min(1, v))
    view.setInt16(44 + i * 2, s < 0 ? s * 0x8000 : s * 0x7fff, true)
  })
  return buffer
}

export function arrayBufferToBase64(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf)
  let binary = ''
  const CHUNK = 0x8000
  for (let i = 0; i < bytes.length; i += CHUNK) binary += String.fromCharCode(...bytes.subarray(i, i + CHUNK))
  return btoa(binary)
}

/** Decodes whatever MediaRecorder produced (audio/mp4 on iOS) and re-encodes as 16 kHz mono WAV base64. */
export async function recordingToWavBase64(blob: Blob): Promise<string> {
  const ctx = new AudioContext()
  try {
    const decoded = await ctx.decodeAudioData(await blob.arrayBuffer())
    const length = Math.ceil(decoded.duration * TARGET_SAMPLE_RATE)
    const offline = new OfflineAudioContext(1, Math.max(1, length), TARGET_SAMPLE_RATE)
    const src = offline.createBufferSource()
    src.buffer = decoded
    src.connect(offline.destination)
    src.start()
    const rendered = await offline.startRendering()
    return arrayBufferToBase64(encodeWav(rendered.getChannelData(0), TARGET_SAMPLE_RATE))
  } finally {
    void ctx.close()
  }
}

export interface Recorder { stop: () => Promise<Blob>; cancel: () => void }

export async function startRecording(): Promise<Recorder> {
  if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === 'undefined') {
    throw new Error('Voice recording is not supported in this browser.')
  }
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
  const recorder = new MediaRecorder(stream)
  const chunks: Blob[] = []
  recorder.ondataavailable = (e) => { if (e.data.size) chunks.push(e.data) }
  const stopTracks = () => stream.getTracks().forEach((t) => t.stop())
  recorder.start()
  return {
    stop: () => new Promise((resolve) => {
      recorder.onstop = () => { stopTracks(); resolve(new Blob(chunks, { type: recorder.mimeType })) }
      recorder.stop()
    }),
    cancel: () => { recorder.onstop = stopTracks; if (recorder.state !== 'inactive') recorder.stop(); else stopTracks() },
  }
}
