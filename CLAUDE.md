# BC Flight Share — Project Guide

## What This App Does
iOS app for Boston College students to find ride-share partners to the airport. Users post a ride with a destination, meeting location at BC, and departure date/time. Other BC students browse a calendar view, tap a date to see all rides posted that day, and join a ride to split the Uber cost.

## Tech Stack
- **Language**: Swift 6 / SwiftUI
- **Backend**: Firebase (Firestore + Firebase Auth)
- **Minimum iOS**: 26.2
- **Architecture**: MVVM with `@Observable` view models
- **Key Swift settings**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`

## Firebase Setup (Required Before Building)
1. Add Firebase via **File → Add Package Dependencies** → `https://github.com/firebase/firebase-ios-sdk`
   - Select only: `FirebaseAuth` and `FirebaseFirestore`
2. Create project at `console.firebase.google.com` → bundle ID: `Alexistheman.BC-Flight-Share`
3. Download `GoogleService-Info.plist` and drag into `BC Flight Share/` folder in Xcode
4. Firebase console: enable **Email/Password** auth and create a **Firestore** database (test mode to start)

## Project Structure

```
BC Flight Share/
├── BC_Flight_ShareApp.swift   — App entry, calls FirebaseApp.configure()
├── ContentView.swift          — Auth gate: shows AuthView or HomeView based on login state
├── AppColors.swift            — Color.bcMaroon and Color.bcGold extensions
├── Models.swift               — Ride and BCUser Codable structs
├── AuthViewModel.swift        — @Observable: sign in, sign up (@bc.edu enforced), sign out
├── RideViewModel.swift        — @Observable: Firestore real-time listener, CRUD for rides
├── AuthView.swift             — Sign in / Create Account screens (SignInForm, SignUpForm)
├── HomeView.swift             — TabView root: injects RideViewModel, owns startListening/stopListening
├── CalendarTabView.swift      — Month calendar grid; dots on dates with rides; DayCell component
├── DayRidesView.swift         — List of RideCards for a tapped date; RideCard component
├── RideDetailView.swift       — Full ride info, rider list, Join/Leave/Delete, Uber deep link
├── CreateRideView.swift       — Form to post a ride; chip pickers for destinations + meeting spots
├── MyRidesView.swift          — All rides the current user has posted or joined
└── ProfileView.swift          — User name/email display, sign out
```

## Data Models

### Ride (Firestore collection: `rides`)
| Field | Type | Notes |
|-------|------|-------|
| `creatorId` | String | Firebase UID of poster |
| `creatorName` | String | Display name |
| `direction` | String? | `"toAirport"` or `"toBC"`; nil on legacy docs (treated as `toAirport`) |
| `destination` | String | The airport in both directions (going TO it or coming FROM it) |
| `terminal` | String | Terminal at the airport (drop-off or arrival) |
| `meetingLocation` | String | BC campus location (pickup for toAirport, dropoff for toBC) |
| `earliestDepartureFromCampus` | Date | Departure from BC (toAirport) or from airport (toBC) |
| `departureWindowMinutes` | Int | Flexibility window in minutes |
| `flightDepartureTime` | Date | Flight departs (toAirport) or flight lands (toBC) |
| `maxRiders` | Int | 2–5 |
| `riders` | [String: RiderInfo] | Map of UID → {name, gender} for all riders |
| `notes` | String | Optional free text |
| `createdAt` | Date | Auto-set on creation |

### BCUser (Firestore collection: `users`)
| Field | Type |
|-------|------|
| `id` | String (Firebase UID) |
| `name` | String |
| `email` | String (@bc.edu enforced) |
| `createdAt` | Date |

## Colors (BC Brand)
- **Maroon**: `Color.bcMaroon` → `rgb(138, 10, 26)` approx
- **Gold**: `Color.bcGold` → `rgb(196, 152, 61)` approx

## Key Design Decisions
- `PBXFileSystemSynchronizedRootGroup` — any `.swift` file dropped in the source folder is auto-included; no need to edit `project.pbxproj`
- `@Observable` (not `ObservableObject`) — modern Swift Observation framework; use `.environment(vm)` / `@Environment(Type.self)` pattern
- `RideViewModel` is created in `HomeView` and passed down via `.environment(rideVM)`; `AuthViewModel` is created in `ContentView`
- `@bc.edu` email check is enforced in `AuthViewModel.signUp()`, not just the UI
- Rides are filtered by date using a `"yyyy-M-d"` dateKey string (year-month-day components, no leading zeros)
- Uber integration: deep-links to `uber://`; falls back to `https://m.uber.com/` if app not installed

## SwiftLint (Code Style)
SwiftLint 0.63.3 is installed via Homebrew. Config is at `.swiftlint.yml` in the project root.

**Run manually:**
```
cd "~/Desktop/John Pork/BC Flight Share"
swiftlint lint "BC Flight Share" "BC Flight ShareTests" "BC Flight ShareUITests"
```

**Auto-fix safe violations:**
```
swiftlint --fix "BC Flight Share"
```

**Key style rules enforced:**
- Max line length: 120 (warning) / 160 (error)
- No trailing commas in arrays/dicts
- Identifiers ≥ 2 chars (`db` allowed; `c` is not — use `comps`)
- Each argument on its own line when a call spans multiple lines
- Prefer `isEmpty` over `== ""` / `count == 0`
- `static` instead of `class` inside `final class`

**Adding to Xcode build phases** (run once per machine):
In Xcode → Target → Build Phases → "+" → New Run Script Phase → paste:
```bash
if which swiftlint > /dev/null; then swiftlint; fi
```
Place it after "Compile Sources". SwiftLint will then run on every build.

## Running Tests
- **Unit tests** (`BC Flight ShareTests`): `Cmd+U` or Product → Test. Tests pure model logic and ViewModel filtering — no network required.
- **UI tests** (`BC Flight ShareUITests`): Run on Simulator. Tests the full auth and calendar flow. Requires the app to build (Firebase must be set up).

## How to Add New Features
1. Add new Swift files to `BC Flight Share/` — Xcode picks them up automatically
2. For new Firestore fields, update `Models.swift` and any affected ViewModel methods
3. Add corresponding unit tests to `BC_Flight_ShareTests.swift` (or a new test file in `BC Flight ShareTests/`)
4. Add UI tests to `BC_Flight_ShareUITests.swift` that cover the new user flow
5. Update this CLAUDE.md with the new feature, files, and any new data model fields

## Known Pre-Firebase-Setup Behavior
All SourceKit errors visible before Firebase is added via SPM are expected — they cascade from `FirebaseFirestore` and `FirebaseAuth` being unresolved. They clear completely once the package is added.

## Security — Completed & Remaining

### Completed
- **Firestore Security Rules** (`firestore.rules`) — replaces open test-mode rules. Enforces `@bc.edu` at the database level, scopes all reads/writes to authenticated users, locks join/leave to the map-diff pattern, enforces the 24 h delete window server-side, caps text fields, makes messages immutable.
- **Removed `groupChatLink`** — field deleted from model, ViewModel, UI, and rules; app uses its own in-app chat.
- **Expired ride cleanup** — removed client-side auto-deletion from `RideViewModel.startListening()`; expired rides are filtered locally and ignored. Firestore accumulates them until a Cloud Function cleans up (see below).
- **Rider data model** — replaced three parallel arrays (`currentRiderIds`, `currentRiderNames`, `currentRiderGenders`) with a single `riders: [String: RiderInfo]` map keyed by Firebase UID. Join/leave are now atomic single-field writes; name changes no longer break leave.

### Remaining
- All previously listed items are complete. See below for what was added.

### Recently Completed
- **Blocking + message flagging** — `BlockViewModel` manages a real-time listener on `users/{uid}/blocks/` subcollection. Long-press any non-own rider in `RideDetailView` or message bubble in `ChatView` to block/flag. Blocked users' rides are filtered from calendar and day views. Reports land in `reports/` collection.
- **Cloud Function — expired ride cleanup** — `cleanupExpiredRides` scheduled hourly in `functions/src/index.ts`; deletes rides where `earliestDepartureFromCampus + departureWindowMinutes + 2h < now`.
- **Firebase Auth blocking function** — `enforceBC` beforeUserCreated trigger in `functions/src/index.ts`; rejects any account not ending in `@bc.edu` before it's created.
- **Firebase Blaze upgrade** — project upgraded to Blaze plan; Cloud Functions deployed. Node runtime bumped to 20. `cleanupExpiredRides` has a `MAX_DELETES_PER_RUN = 400` safety cap. Artifact Registry cleanup policy set (images deleted after 1 day). Budget alert at $5/month.
- **Dev account whitelist** — `alexdardarian@gmail.com` whitelisted in `enforceBC` (Cloud Function), `AuthViewModel.devWhitelist` (client), and `isDevAccount()` in `firestore.rules` so the dev account can sign in without a `@bc.edu` address.

---

## Cloud Functions (Deploy)
```
cd "~/Desktop/John Pork/BC Flight Share/functions"
npm install
npm run build
cd ..
firebase deploy --only functions,firestore:rules
```
Requires `firebase-tools` installed (`npm install -g firebase-tools`) and `firebase login`.

---

## Safety Audit — App Store Checklist

### 🔴 Tier 1 — App Store Blockers

1. **Privacy Policy** — ⚠️ NEEDS HOSTING: Written at `docs/privacy.md`. Enable GitHub Pages on the repo (Settings → Pages → Source: Deploy from branch `main`, folder `/docs`) to publish it at `https://alexdardarian.github.io/BC-Flight-Share/privacy`. `NSPrivacyPolicyURL` key is now set in `project.pbxproj` (via `INFOPLIST_KEY_NSPrivacyPolicyURL`). App Store will reject without the page being live.
2. **Terms of Service** — ⚠️ NEEDS HOSTING: Written at `docs/terms.md`. Same GitHub Pages setup publishes it at `https://alexdardarian.github.io/BC-Flight-Share/terms`. `ProfileView.swift` URLs already point to both pages.
3. ✅ **Liability disclaimer in-app** — Added to `RideDetailView` above the Join button (hidden for creators/joined riders).
4. ✅ **Full names + genders gated** — `RideDetailView.riderRow` now shows first name + last initial and hides gender for non-joined, non-creator users. `DayRidesView.RideCard` no longer shows `creatorGender`.

### 🟡 Tier 2 — Launch Safety

5. ✅ **Age confirmation at signup** — "I confirm I am 18 years of age or older" toggle added to `SignUpForm`; blocks account creation until checked.
6. ✅ **Gender hidden from non-joined users** — Handled in Tier 1 item 4 above.
7. ✅ **Rate-limit ride creation** — Client-side 5-ride cap enforced in `CreateRideView` via `RideViewModel.activeRideCount(for:)`.
8. ✅ **Meeting location warning** — Footer added to meeting location section in `CreateRideView`: "Use a public campus location. Do not enter a personal address."
9. ✅ **"Not affiliated with BC" disclaimer** — Added to `ProfileView` About section.

### 🟢 Tier 3 — Post-Launch Polish

10. **Rider ratings/reviews** — Simple 5-star after ride completion; visible on rider profile.
11. **"I arrived safely" button** — Appears in `MyRidesView` after `departureEndTime` passes.
12. **Account deletion flow** — Button in `ProfileView` that deletes Firestore user doc, all authored rides, and signs out. Required for App Store (GDPR/CCPA) in some markets.
13. **Accessibility** — Add `.accessibilityLabel` to all icon-only buttons and colored badges.
14. **Emergency contact field** — Optional field on profile, stored in `users/{uid}`, never shown to other users.
