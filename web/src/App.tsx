import { useEffect, useState } from 'react'
import { useProfile } from './hooks'
import { db, newId } from './lib/db'
import { ToastProvider } from './ui/controls'
import { DumbbellIcon, GridIcon, HomeIcon, PersonIcon, PlusIcon } from './ui/icons'
import { Home } from './screens/Home'
import { Tracker } from './screens/Tracker'
import { More } from './screens/More'
import { Onboarding } from './screens/Onboarding'
import { QuickLog } from './screens/QuickLog'
import { WorkoutTab } from './screens/workout/WorkoutTab'
import type { Appearance } from './lib/goals'

type Tab = 'home' | 'tracker' | 'workout' | 'more'

function useAppearance(appearance: Appearance) {
  useEffect(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)')
    const apply = () => {
      const dark = appearance === 'Dark' || (appearance === 'System' && media.matches)
      document.documentElement.dataset.theme = dark ? 'dark' : 'light'
      document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? '#121212' : '#F1F4F1')
    }
    apply()
    media.addEventListener('change', apply)
    return () => media.removeEventListener('change', apply)
  }, [appearance])
}

export default function App() {
  const { profile, loaded } = useProfile()
  useAppearance(profile.appearance)
  if (!loaded) return null
  return <ToastProvider>{profile.hasCompletedOnboarding ? <MainTabs /> : <Onboarding />}</ToastProvider>
}

const TABS: { id: Tab; label: string; Icon: () => React.JSX.Element }[] = [
  { id: 'home', label: 'Home', Icon: HomeIcon },
  { id: 'tracker', label: 'Tracker', Icon: GridIcon },
  { id: 'workout', label: 'Workout', Icon: DumbbellIcon },
  { id: 'more', label: 'More', Icon: PersonIcon },
]

function MainTabs() {
  const [tab, setTab] = useState<Tab>('home')
  const [quickLog, setQuickLog] = useState(false)
  const [openWorkout, setOpenWorkout] = useState<string | null>(null)

  const startWorkout = async () => {
    const active = await db.workouts.filter((w) => !w.endedAt).first()
    const id = active?.id ?? newId()
    if (!active) await db.workouts.add({ id, name: 'Workout', startedAt: Date.now(), sets: [] })
    setTab('workout'); setOpenWorkout(id)
  }

  const tabButton = ({ id, label, Icon }: (typeof TABS)[number]) => (
    <button key={id} className="tab" aria-current={tab === id ? 'page' : undefined} onClick={() => setTab(id)}><Icon />{label}</button>
  )

  return (
    <>
      <main style={{ height: '100%' }}>
        {tab === 'home' && <Home />}
        {tab === 'tracker' && <Tracker />}
        {tab === 'workout' && <WorkoutTab openId={openWorkout} onOpen={setOpenWorkout} />}
        {tab === 'more' && <More />}
      </main>
      <nav className="tabbar" aria-label="Main">
        {TABS.slice(0, 2).map(tabButton)}
        <button className="fab" aria-label="Quick log" onClick={() => setQuickLog(true)}><PlusIcon /></button>
        {TABS.slice(2).map(tabButton)}
      </nav>
      {quickLog && <QuickLog onClose={() => setQuickLog(false)} onStartWorkout={() => void startWorkout()} />}
    </>
  )
}
