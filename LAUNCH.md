# KAAND launch guide (non-commercial)

This project can be launched as a free, non-commercial news reader using a
Vercel Hobby backend, Google News RSS, and a Guardian developer key.

## 1. Secure configuration

1. Register a personal Guardian developer key at
   <https://open-platform.theguardian.com/access/>.
2. Create `backend/.env.local` locally with:

   ```env
   GUARDIAN_API_KEY=your_guardian_developer_key
   ```

3. Rotate any previously exposed Guardian key. Do not commit keys, Firebase
   service-account files, Android signing keys, or `backend/.env.local`.

The application still works with Google News RSS if the Guardian variable is
not configured; only Guardian editorial content is unavailable.

## 2. Run locally

Start the API server:

```powershell
cd backend
npm.cmd run dev
```

Run the Flutter application from the repository root:

```powershell
flutter run
```

Android emulators use `10.0.2.2` automatically. For a physical device, pass a
reachable backend address instead of localhost:

```powershell
   flutter run --dart-define=API_BASE_URL=https://kaand-cyan.vercel.app/api
```

## 3. Deploy the backend

1. Import the `backend` directory as a Next.js project in Vercel.
2. Add `GUARDIAN_API_KEY` as an environment variable for Production and
   Preview.
3. Deploy, then verify `https://your-api-domain/api/health` returns HTTP 200.
4. Build the mobile app with that API URL:

   ```powershell
   flutter build appbundle --release --dart-define=API_BASE_URL=https://kaand-cyan.vercel.app/api
   ```

## 4. Release checks

- Confirm Home, Search, Discover, Bookmarks, Profile, article details, share,
  and external article links on a physical Android device.
- Confirm Home still loads when Guardian is unavailable.
- Test the Guardian quota/error state separately.
- Replace development Firebase configuration with the production Firebase
  project configuration before shipping.
- Create and store the Android release signing key outside this repository.
- Review publisher attribution and terms before public distribution.

## 5. Free-tier boundaries

The Vercel Hobby and Guardian developer tiers are appropriate only for this
non-commercial, small-scale launch. Monitor their current quota and use terms
before promoting the app or increasing traffic.
