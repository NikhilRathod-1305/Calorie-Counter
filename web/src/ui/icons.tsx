const base = { fill: 'none', stroke: 'currentColor', strokeWidth: 1.8, strokeLinecap: 'round', strokeLinejoin: 'round', viewBox: '0 0 24 24' } as const

export const HomeIcon = () => <svg {...base}><path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z" /></svg>
export const GridIcon = () => <svg {...base}><rect x="3" y="3" width="7.5" height="7.5" rx="2" /><rect x="13.5" y="3" width="7.5" height="7.5" rx="2" /><rect x="3" y="13.5" width="7.5" height="7.5" rx="2" /><rect x="13.5" y="13.5" width="7.5" height="7.5" rx="2" /></svg>
export const DumbbellIcon = () => <svg {...base}><path d="M6 7v10M3.5 9.5v5M18 7v10M20.5 9.5v5M6 12h12" /></svg>
export const PlusIcon = () => <svg {...base} strokeWidth={2.6}><path d="M12 5v14M5 12h14" /></svg>
export const PersonIcon = () => <svg {...base}><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7" /></svg>
