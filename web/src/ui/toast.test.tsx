// @vitest-environment jsdom
import { act, cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, test, vi } from 'vitest'
import { ToastProvider, useToast } from './controls'

function Trigger({ onUndo }: { onUndo?: () => void }) {
  const toast = useToast()
  return <button onClick={() => toast('Deleted', onUndo ? { label: 'Undo', onClick: onUndo } : undefined)}>go</button>
}

afterEach(() => { cleanup(); vi.useRealTimers() })

describe('toast', () => {
  test('runs the undo action and dismisses', () => {
    vi.useFakeTimers()
    const onUndo = vi.fn()
    render(<ToastProvider><Trigger onUndo={onUndo} /></ToastProvider>)

    fireEvent.click(screen.getByText('go'))
    fireEvent.click(screen.getByRole('button', { name: 'Undo' }))
    act(() => { vi.advanceTimersByTime(300) })

    expect(onUndo).toHaveBeenCalledOnce()
    expect(screen.queryByRole('status')).toBeNull()
  })

  test('hides a plain toast after a short delay', () => {
    vi.useFakeTimers()
    render(<ToastProvider><Trigger /></ToastProvider>)

    fireEvent.click(screen.getByText('go'))
    expect(screen.getByRole('status').textContent).toBe('Deleted')
    act(() => { vi.advanceTimersByTime(2500) })

    expect(screen.queryByRole('status')).toBeNull()
  })
})
