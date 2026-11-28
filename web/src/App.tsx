import { useCallback, useEffect, useState } from 'react'
import { useAppBadge, usePrefs, useProfile } from './hooks'
import { db, newId } from './lib/db'
import { ToastProvider } from './ui/controls'
import { DumbbellIcon, GridIcon, HomeIcon, PersonIcon, PlusIcon } from './ui/icons'
import { Home } from './screens/Home'
import { Tracker } from './screens/Tracker'
import { More } from './screens/More'
import { Onboarding } from './screens/Onboarding'
import { QuickLog, panelFor, type Panel } from './screens/QuickLog'
import type { LaunchAction } from './lib/prefs'
import { useLongPress } from './ui/useLongPress'
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

/** Away this long, coming back counts as "opening the app" for the launch-screen setting. */
const RELAUNCH_AFTER_MS = 10 * 60_000

/** Quick Log state: closed, the tile menu, or straight into one panel. */
type QuickLogState = { initial: Panel } | null

const launchState = (launch: LaunchAction): QuickLogState =>
  launch === 'home' ? null : launch === 'quicklog' ? { initial: null } : { initial: panelFor(launch) }

/** Re-applies the launch screen when the app returns after a long time in the background. */
function useRelaunch(onRelaunch: () => void) {
  useEffect(() => {
    let hiddenAt = 0
    const onVis = () => {
      if (document.visibilityState === 'hidden') { hiddenAt = Date.now(); return }
      if (hiddenAt && Date.now() - hiddenAt >= RELAUNCH_AFTER_MS && !document.querySelector('.overlay')) onRelaunch()
    }
    document.addEventListener('visibilitychange', onVis)
    return () => document.removeEventListener('visibilitychange', onVis)
  }, [onRelaunch])
}

function MainTabs() {
  const prefs = usePrefs()
  useAppBadge(prefs.badge)
  const [tab, setTab] = useState<Tab>('home')
  const [quickLog, setQuickLog] = useState<QuickLogState>(() => launchState(prefs.launch))
  const relaunch = useCallback(() => { setTab('home'); setQuickLog(launchState(prefs.launch)) }, [prefs.launch])
  useRelaunch(relaunch)
  const fab = useLongPress(() => setQuickLog({ initial: null }), () => setQuickLog({ initial: panelFor(prefs.longPress) }))
  const [openWorkout, setOpenWorkout] = useState<string | null>(null)

  const startWorkout = async () => {
    const active = await db.workouts.filter((w) => !w.endedAt).first()
    const id = active?.id ?? newId()
    if (!active) await db.workouts.add({ id, name: 'Workout', startedAt: Date.now(), sets: [] })
    setTab('workout'); setOpenWorkout(id)
  }

  const tabButton = ({ id, label, Icon }: (typeof TABS)[number]) => (
    <button key={id} className="tab" aria-current={tab === id ? 'page' : undefined} onClick={() => { setTab(id); window.scrollTo(0, 0) }}><Icon />{label}</button>
  )

  return (
    <>
      <main key={tab} className="tab-view">
        {tab === 'home' && <Home />}
        {tab === 'tracker' && <Tracker />}
        {tab === 'workout' && <WorkoutTab openId={openWorkout} onOpen={setOpenWorkout} />}
        {tab === 'more' && <More />}
      </main>
      <nav className="tabbar" aria-label="Main">
        {TABS.slice(0, 2).map(tabButton)}
        <button className={`fab${fab.holding ? ' holding' : ''}`} aria-label="Quick log" aria-description={`Hold for ${prefs.longPress === 'water' ? 'drink log' : `${prefs.longPress} log`}`} {...fab.handlers}><PlusIcon /></button>
        {TABS.slice(2).map(tabButton)}
      </nav>
      {quickLog && <QuickLog initial={quickLog.initial} onClose={() => setQuickLog(null)} onStartWorkout={() => void startWorkout()} />}
    </>
  )
}
