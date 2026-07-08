# RideGo Customer App (Flutter)

A fully interactive, responsive, stateful implementation of the RideGo customer app UI, matching the provided design exactly.

## What changed in this update

**Every screen is now functional**, not just a static UI:
- **Login** - phone number is validated (must be 10 digits) before continuing, with inline error text.
- **OTP** - 4 real input boxes with auto-advance/auto-back focus, a live 30s countdown, resend, and validation before "Verify" works.
- **Profile Setup** - name/email fields are editable and persist into the app's state (shown later on the Profile screen).
- **Search Destination** - typing and tapping recent/popular places actually sets your drop location, which flows through Confirm Ride, Ride Completed, etc.
- **Vehicle Selection** - tapping a vehicle actually selects it (highlight + checkmark) and updates the fare/ride type used on every later screen.
- **Payment Method** - tapping a method actually selects it; paying records a transaction and (if Wallet is chosen) deducts from your wallet balance.
- **Rating & Review** - stars are tappable and your review text is saved.
- **Ride History** - All / Completed / Cancelled tabs actually filter the list; completed rides are added automatically after each trip.
- **Wallet** - "Add Money" opens a real dialog and updates your balance + transaction list live.
- **Profile** - shows your real saved name/phone, edit icon reopens Profile Setup, Logout actually logs you out, menu items respond to taps.
- All of this is backed by a single mutable `RideController` (`lib/controllers/ride_controller.dart`) so state is consistent as you move between screens - no backend needed, everything runs in memory.

**Splash screen & "Finding Driver" screen glitch - fixed.**
Both screens previously centered their content with `Column` + `Spacer()`, which can momentarily render in the top-left corner of the screen (especially on web/desktop) while layout constraints settle. They now use `SizedBox.expand` + `Center`/`Align`, which keeps the content correctly centered on every screen size from the very first frame. A `web/index.html` with corrected viewport meta tags and full-height CSS is also included as an extra safeguard if you run this on Flutter Web.

**Responsive.** The whole app now also centers itself with a max width on tablets/desktop browsers (see the `builder` in `lib/app.dart`) instead of stretching a phone-style layout edge-to-edge, while staying full-width on actual phones.

**Images folder.** `assets/images/` now contains real placeholder PNGs (logo, splash car, driver avatar, profile avatar, map background) wired into the relevant screens, with graceful fallbacks to icons if an image ever fails to load. Swap these files out with your own branding/photos - same filenames, same `assets/images/` path, already registered in `pubspec.yaml`.

## Project structure
```
lib/
  app.dart                  - MaterialApp + theme + responsive wrapper
  main.dart                 - entry point
  controllers/ride_controller.dart   - single source of truth for app state
  models/                   - plain data classes (vehicle, payment, ride summary, etc.)
  core/
    constants/              - colors, strings, dimensions
    routes/                 - named route table
    utils/responsive.dart   - screen-size helpers
  views/
    screens/                - one file per screen (18 screens)
    widgets/                - shared UI pieces (buttons, cards, map, etc.)
assets/images/               - app images (logo, avatars, map background)
web/                          - index.html / manifest.json with corrected viewport sizing
```

## How to run
1. Make sure the Flutter SDK is installed (`flutter --version`).
2. Unzip this project, then from the project root:
   ```
   flutter create . --platforms=android,ios,web
   flutter pub get
   flutter run
   ```
3. The app starts at the Splash screen and flows: Login -> OTP -> Profile Setup -> Home -> Search -> Vehicle Selection -> Confirm Ride -> Finding Driver -> Driver Assigned -> Live Tracking -> Ride In Progress -> Ride Completed -> Payment -> Rating, plus Ride History / Wallet / Profile from the bottom navigation.

## Next steps (to make it production-ready)
- Swap the custom-painted `RideMap` widget for `google_maps_flutter` + real geolocation.
- Connect Login/OTP to Firebase Phone Auth.
- Replace `RideController`'s in-memory state with real API/Firebase calls.
- Add real-time driver tracking via sockets or Firebase Realtime Database.
