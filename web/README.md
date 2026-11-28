# Count on Me — web app (PWA)

Installable web version of the iOS app. It runs from the iPhone Home Screen, works offline, and never expires.

## Install on iPhone
1. Open the deployed URL in **Safari**.
2. Share → **Add to Home Screen** → Add.
3. Optional: More → Gemini API Key for photo/voice/text logging.

Data is stored on the device (IndexedDB). Use More → Back up data now and then.
To bring data over from the iOS app, export the CSV there (More → Export Data), save it to Files, then use More → Import from iOS app.

## Develop
```bash
npm install
npm run dev        # local dev server
npm test           # unit tests (vitest)
npm run build      # production build + service worker → dist/
npx vite preview --port 4173 & npm run e2e   # browser smoke test (uses local Google Chrome)
```

## Deploy
`.github/workflows/deploy-web.yml` builds `web/` and publishes it to GitHub Pages on every push to `main` that touches `web/`.
One-time setup: repo Settings → Pages → Source: **GitHub Actions**.

## What differs from the iOS app
- No Apple Health steps and no Siri shortcuts (browsers can't access them).
- Voice is recorded and sent straight to Gemini (no on-device speech recognition).
- Workout calories are a MET-based estimate from session time and body weight.

## Shortcuts & badge (More → Shortcuts & badge)
- **Icon badge**: calories left, glasses of water left (250 ml) or main meals left, shown on the Home Screen icon. iOS 16.4+ only shows it after notifications are allowed for the app; it updates whenever the app is used, not while it's closed.
- **Hold +**: jumps straight to a chosen log screen (default: voice). A tap still opens the Quick Log menu.
- **Open app to**: launch screen, also applied when the app returns after 10+ minutes in the background.
- Real iOS widgets aren't possible for web apps.
