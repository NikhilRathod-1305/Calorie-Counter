import { describe, expect, test } from 'vitest'
import { encodeWav } from './audio'

describe('encodeWav', () => {
  test('writes a 16-bit mono PCM RIFF header and clamps samples', () => {
    const buf = encodeWav(new Float32Array([0, 1, -1, 2]), 16000)
    const view = new DataView(buf)
    const tag = (o: number) => String.fromCharCode(...new Uint8Array(buf, o, 4))
    expect(tag(0)).toBe('RIFF')
    expect(tag(8)).toBe('WAVE')
    expect(view.getUint16(22, true)).toBe(1) // channels
    expect(view.getUint32(24, true)).toBe(16000)
    expect(view.getUint32(40, true)).toBe(8) // 4 samples * 2 bytes
    expect(view.getInt16(46, true)).toBe(32767)
    expect(view.getInt16(48, true)).toBe(-32768)
    expect(view.getInt16(50, true)).toBe(32767) // clamped
  })
})
