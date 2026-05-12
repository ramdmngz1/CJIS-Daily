# CJIS Daily — Changelog

---

## 2026-05-08

### Code Review — Cross-Platform Pre-Release Pass

External code review of all iOS Swift and Android Kotlin source files. Three critical bugs (one of which silently regressed `BOOT_COMPLETED` rescheduling on Android), one cross-platform behavioral mismatch in the streak math, and one cross-platform mismatch in the daily-tip rotation formula. All fixes applied to both platforms where applicable.

#### Bug Fix — Critical — `BootReceiver` Never Receives `BOOT_COMPLETED` (`AndroidManifest.xml`)

**Root cause:** On 2026-03-14 the `BootReceiver` was changed to `android:exported="false"` as a "security fix." That change was incorrect. `BOOT_COMPLETED` is a protected system broadcast that *only* the OS can send, and starting in API 31+ Android requires receivers that filter on system-defined actions to be exported so the system can deliver the intent. With `exported="false"`, the receiver never fires after a reboot, and the daily reminder `WorkManager` task is never re-scheduled until the user opens the app and re-saves the reminder time. Users who reboot their phone silently lose the daily notification.

The original 2026-03-14 reasoning ("an exported receiver without a permission guard can be triggered by any installed app") doesn't apply here: `BOOT_COMPLETED` is a protected action — third-party apps cannot send it — and the `RECEIVE_BOOT_COMPLETED` permission is a self-permission the app already declares.

**Fix:**
- `AndroidManifest.xml` — `BootReceiver android:exported` flipped back to `"true"`.

#### Bug Fix — Critical — Streak Always Increments by 1 on Android (`CJISViewModel.kt`)

**Root cause:** `finishQuiz()` updated the streak with `streakCount = current.streakCount + 1` unconditionally, with no check for whether the previous completion was actually one calendar day ago. iOS `QuizProgressManager.bumpStreak` correctly resets the streak to 1 when the gap isn't 1 day. Result: an Android user who took the check today, then again 30 days later, ended up with a streak of 2 instead of 1. iOS and Android streaks for the same user could differ wildly.

**Fix (`CJISViewModel.kt`):**
- Added `nextStreak(lastDayKey, todayKey, currentStreak)` helper that parses both ISO date strings, computes `ChronoUnit.DAYS.between`, and returns `currentStreak + 1` only when the diff is exactly `1L`. Otherwise resets to `1`. Empty/malformed last-day-key also resets to `1`.
- `finishQuiz()` now calls `nextStreak(...)` instead of unconditionally incrementing.
- Mirrors the iOS `QuizProgressManager.bumpStreak(for:)` semantics so streak counts now agree across platforms for the same calendar history.

#### Bug Fix — Critical — Stale Daily State Across Midnight (`DailyPackProgressManager.swift`)

**Root cause:** This re-applies `resetIfNewDay()` calls inside the `isDailyCheckCompleted` and `todaysScore` getters that the 2026-03-09 entry removed for "performance." That earlier removal was based on the assumption that `DailyPackView.onAppear` (and later `willEnterForegroundNotification` from 2026-03-14) would always run before any read. That holds for the main view, but:

1. The singleton is shared, and any other consumer reading `isDailyCheckCompleted` outside the `DailyPackView` render path (e.g., a future widget, complication, intent extension, or unit test) sees stale state.
2. The "performance" concern was overstated: `resetIfNewDay()` early-returns on a string compare when the day hasn't changed (`guard state.dayKey != todayKey else { return }`), so the only cost on the hot path is a single string equality check — no encoding, no UserDefaults write.

**Fix:**
- `DailyPackProgressManager.swift` — `isDailyCheckCompleted` and `todaysScore` getters now call `resetIfNewDay()` before returning state, restoring the self-healing behavior on day rollover. The body of `DailyPackView` continues to call `refreshForCurrentDay()` via `onAppear` / `willEnterForeground`, so the change is purely defense-in-depth in the common path.

#### Bug Fix — High — iOS / Android Daily Tip Rotation Formula Mismatch (`DataRepository.kt`)

**Root cause:** iOS `TipStore.tipsForToday` uses `((dayOfYear - 1) * count) % size` for the rotation start index. Android `DataRepository.tipsForToday` was using `(dayOfYear * count) % size` — off by one day's worth of pack offset. Two users with both apps installed (or one user across platforms) saw different sets of tips on the same calendar day. The 2026-03-11 entry's claim that Android "uses the same deterministic day-of-year rotation algorithm as iOS" was inaccurate.

**Fix (`DataRepository.kt`):**
- Changed `(dayOfYear * count) % size` → `((dayOfYear - 1) * count).mod(size)`. Used Kotlin's `.mod()` instead of `%` so a negative product (defensive — shouldn't happen in practice, but `dayOfYear` could in theory be 0 if the API ever changed) still produces a non-negative index.

#### Bug Fix — High — Duplicate Tips When Library Smaller Than Pack Size (`DataRepository.kt`)

**Root cause:** `tipsForToday` mapped `(0 until count)` directly through the modulo formula, so when `tipsWithQuizzes.size < count` the same tip appeared twice in the same day's pack. iOS guards against this with a `Set<Int>` dedupe loop in `TipStore.tipsForToday`. Android did not.

**Fix (`DataRepository.kt`):**
- Replaced the simple `(0 until count).map { ... }` with a dedupe loop using `mutableSetOf<Int>()` to track seen `tip.id`s, mirroring iOS. The loop iterates up to `tipsWithQuizzes.size` candidates and emits at most `min(count, tipsWithQuizzes.size)` unique tips.
- Also added an explicit `count <= 0` early-return guard.

#### Hardening — Notification Permission Not Re-Prompted Each Launch (`MainActivity.kt`)

**Root cause:** `onCreate` called `notificationPermissionLauncher.launch(POST_NOTIFICATIONS)` unconditionally on every Activity creation (Android 13+). Android's permission system suppresses the prompt after a hard deny, but the launcher invocation itself is still wasteful and noisy in lifecycle traces.

**Fix (`MainActivity.kt`):**
- Wrapped the launcher call in a `ContextCompat.checkSelfPermission(...) == PERMISSION_GRANTED` gate. Now only requested when actually needed.
- Added imports for `android.content.pm.PackageManager` and `androidx.core.content.ContextCompat`.

#### Hardening — Race-Safe Quiz Submission (`CJISViewModel.kt`)

**Root cause:** `selectAnswer` and `submitAnswer` did not guard against state mutation after the quiz had already been finished, and `submitAnswer` did not guard against a second submission of the same question (which would double-increment `_quizCorrectCount`).

**Fix (`CJISViewModel.kt`):**
- `selectAnswer`: early return if `_quizFinished.value`.
- `submitAnswer`: early return if `_quizFinished.value`, and additionally early return if `_submittedAnswerIndex.value != null` (already submitted this question).

#### Refactor — Single Source of Truth for Streak Math (`QuizProgressManager.swift`)

**Root cause:** Streak logic was duplicated between `recordDailyCheckIfNeeded` and the now-legacy `markDailyCompletedIfNeeded`. A future change to one path could miss the other.

**Fix (`QuizProgressManager.swift`):**
- Extracted `private func bumpStreak(for date: Date)` as the single implementation. Both call sites now delegate to it.
- `markDailyCompletedIfNeeded` retains its early-return check for "already counted today" to avoid an unnecessary `persist()` write when nothing changed.
- Behavior is unchanged.

#### Hardening — Persist Failures No Longer Silent in DEBUG (`QuizProgressManager.swift`)

**Root cause:** `persist()` used `try? JSONEncoder().encode(state)` which silently dropped any encoding error. While `Codable` failures are rare on simple struct types, a future field addition that's not encodable would fail to persist with no observable signal.

**Fix (`QuizProgressManager.swift`):**
- Replaced `try?` with `do/try/catch`. In DEBUG, `assertionFailure` surfaces the error during development. In Release, the in-memory state is preserved and the next `persist()` will retry.

#### Performance — Cache Daily Quiz Questions (`DailyCheckView.swift`)

**Root cause:** `questions` was a computed property running `tips.compactMap { DailyQuizStore.shared.questions(for: $0.id).first }` on every body re-evaluation. SwiftUI re-evaluates `body` frequently (on every state change, including the user tapping a multiple-choice option), so the lookup repeated unnecessarily.

**Fix (`DailyCheckView.swift`):**
- `questions` is now `@State private var questions: [QuizQuestion] = []`, seeded once via `.onAppear` if empty. The view's `tips` parameter is `let`-immutable for the lifetime of the view, so cache invalidation is unnecessary.

### Deferred (Reviewed, Not Changed)

- **`Models.kt` — `DailyPackProgress.score` nullability mismatch with iOS.** iOS uses `Score?` (nullable); Android uses a `DailyScore(0, 0)` sentinel. Aligning would require coordinated edits across `DailyPackScreen`, `ResultsScreen`, and `CJISViewModel` to handle null. The sentinel works correctly in current callers, so left as a future tech-debt item.
- **`TipStore.swift` — `dayOfYear` rotation resets every January 1st.** On Jan 1 next year users see the same pack as Jan 1 this year. Confirmed intentional per the in-source comment ("Deterministic rotation with wraparound (no randomness during App Review)").
- **`DailyReminderWorker.kt` — generic `android.R.drawable.ic_dialog_info` notification icon.** Replacing with a branded monochrome vector requires a new asset; left for the next icon pass.
- **`CJISViewModel.kt` — DataStore read with `.first()` is non-reactive.** Out-of-band writes (e.g., from `BootReceiver`) won't update the UI. Not a bug today since nothing else writes those keys, but a maintainability note for future widget/intent work.

---

## 2026-03-20

### Content Fix — Quiz Answer Distribution (`cjis_quizzes.json`)

All 730 quiz questions had heavily skewed correct-answer positions: 63% (465) were index 1 (B), 33% (241) were index 2 (C), 2% (17) were index 0 (A), and less than 1% (7) were index 3 (D). This made the quiz trivially predictable — users could answer B on every question and score ~63%.

**Fix:** For each question, the choices array was rotated so the correct answer lands at a new position, with the target positions distributed evenly across all questions using a fixed-seed shuffle. The correct answer text and explanation for every question are unchanged.

**Before:**
- A: 17 (2%) · B: 465 (63%) · C: 241 (33%) · D: 7 (1%)

**After:**
- A: 183 (25%) · B: 183 (25%) · C: 182 (25%) · D: 182 (25%)

Both platform files updated:
- `iOS/CJIS Daily/cjis_quizzes.json`
- `Android/Project/app/src/main/res/raw/cjis_quizzes.json`

---

## 2026-03-18

### Android Parity — Pre-Submission Review Fixes

Applied all fixes from today's iOS pre-submission review to the Android codebase.

#### Bug Fix — Score Values Not Clamped (`CJISViewModel.kt`)

Mirrored the iOS `QuizProgressManager` and `DailyPackProgressManager` clamping fix. In `finishQuiz()`, both `correct` and `total` are now clamped before being used to update `DailyPackProgress.score` and the lifetime stats in `QuizProgress`:

```kotlin
val clampedTotal = maxOf(0, total)
val clampedCorrect = maxOf(0, minOf(correct, clampedTotal))
```

`DailyScore`, `lifetimeCorrect`, and `lifetimeAnswered` now use the clamped values, preventing `lifetimeCorrect > lifetimeAnswered` if a caller ever passes out-of-range values.

#### UX Fix — Misleading Empty State (`DailyPackScreen.kt`)

When `tips` is empty (bundled `cjis_tips.json` fails to decode), the tips area previously showed nothing — just a blank column. Added an explicit empty state message matching the iOS fix:
- Shows `"Tips unavailable. Please reinstall the app."` centered in the tips area when `tip == null`.

---

### App Store Submission Fix — Privacy Manifest (`PrivacyInfo.xcprivacy`)

Apple requires a privacy manifest for all App Store submissions (enforced since Spring 2024). Without it, App Store Connect rejects the archive at upload time.

- Created `CJIS Daily/PrivacyInfo.xcprivacy` declaring:
  - `NSPrivacyTracking: false` — app does not track users across apps or websites
  - `NSPrivacyCollectedDataTypes: []` — no data collected, sent, or shared off-device
  - `NSPrivacyTrackingDomains: []` — no tracking domains
  - `NSPrivacyAccessedAPITypes`: `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` — UserDefaults used solely to persist per-user app settings (theme, notification time, quiz progress, daily completion state)

**Action required in Xcode:** Add `PrivacyInfo.xcprivacy` to the *CJIS Daily* target under Build Phases → Copy Bundle Resources. Xcode will then embed it in the app bundle automatically.

---

### Pre-Submission Review — iOS

Full audit of all 19 Swift source files prior to external TestFlight/App Store submission. No security vulnerabilities found (zero network calls, no API keys, no hardcoded secrets, all `print` statements DEBUG-guarded, ATS is default/secure, no force-unwraps, no retain cycles).

Two defensive coding gaps and one UX issue addressed:

#### Bug Fix — Score Values Not Clamped (`QuizProgressManager.swift`)

**Root cause:** `recordDailyCheckIfNeeded(correct:total:)` accumulated lifetime score with `max(0, correct)` / `max(0, total)` independently. A caller passing `correct > total` (impossible from `DailyCheckView` today, but not enforced at the API boundary) could produce `lifetimeCorrect > lifetimeAnswered`, violating the invariant already checked in `init`.

- `correct` is now clamped to `[0, total]` before accumulation:
  ```swift
  let clampedTotal = max(0, total)
  let clampedCorrect = max(0, min(correct, clampedTotal))
  ```

#### Bug Fix — Score Values Not Clamped (`DailyPackProgressManager.swift`)

**Root cause:** `markDailyCheckCompleted(correct:total:)` stored `Score(correct: correct, total: total)` with no validation. Same boundary enforcement applied:
- `clampedTotal = max(0, total)`, `correct` clamped to `[0, clampedTotal]` before constructing `Score`.

#### UX Fix — Misleading Empty State Text (`DailyPackView.swift`)

- Changed `emptyState` text from `"Loading tips…"` → `"Tips unavailable. Please reinstall the app."`
- The empty state only appears if the bundled `cjis_tips.json` fails to decode — content is not "loading" from a server; showing a spinner-style message incorrectly implies a transient network state.

---

## 2026-03-14

### Security Review — iOS & Android

#### Android — High Severity

**H1 — `android:allowBackup` disabled (`AndroidManifest.xml`)**
- Changed `allowBackup` from `true` → `false`. When enabled, app data (DataStore preferences, quiz progress, streak counts) is extractable via `adb backup` or Google cloud backup without rooting the device.

**H2 — `BootReceiver` not exported (`AndroidManifest.xml`)**
- Changed `BootReceiver android:exported` from `true` → `false`. An exported `BroadcastReceiver` without a permission guard can be triggered by any installed app, allowing arbitrary rescheduling of the daily reminder WorkManager task.

#### Android — Medium Severity

**M1 — ProGuard rules tightened (`app/proguard-rules.pro`)**
- Changed `-keep class` → `-keepclassmembers class` for `com.refuge.cjisdaily.data.**`. The previous rule preserved class names in the release APK, making the package structure partially reversible. With `-keepclassmembers`, only field/method names needed for Gson reflection are preserved; class names are still obfuscated.
- Changed `-keepattributes *Annotation*` → explicit `RuntimeVisibleAnnotations,RuntimeVisibleParameterAnnotations` to avoid preserving unnecessary metadata.

**M2 — Gson deserialization crash guarded (`CJISViewModel.kt`)**
- Wrapped both `gson.fromJson()` calls in `init` with `try-catch`. Previously a corrupted DataStore entry (e.g. from a mid-write crash or upgrade) would throw an uncaught exception during ViewModel initialization, crashing the app on launch.

#### iOS — Medium Severity

**M1 — Production logging removed (`NotificationManager.swift`, `DailyQuizStore.swift`, `AppViewModel.swift`, `TipStore.swift`)**
- Wrapped all `print()` statements with `#if DEBUG` compilation guards. In a Release build, debug log strings containing internal class names, file paths, and error details are visible to anyone with a device logs tool (e.g. Console.app, `idevicesyslog`). Affected call sites: 4 in `NotificationManager.swift`, 3 in `DailyQuizStore.swift`, 1 in `AppViewModel.swift`, 1 in `TipStore.swift`.

#### Deferred / Out of Scope

- **iOS H1**: Migrate quiz progress and streak data from `UserDefaults` to the iOS Keychain — architectural change deferred.
- **iOS M2**: Replace `precondition()` in `QuizQuestion.swift` with `guard + throw` — already addressed in the 2026-03-09 entry; confirmed resolved.
- **iOS M3**: Certificate pinning for the privacy policy URL — requires SSL certificate details; deferred.

---

### Bug Fix — Daily Check Goes to Results Screen (iOS)

**Root cause:** In `DailyCheckView.advanceOrFinish()`, the last question called `onFinished(correctCount, questions.count)` followed immediately by `dismiss()`. The `onFinished` callback in `DailyPackView` set `activeSheet = .results`, but then `dismiss()` — which is bound to the `.dailyCheck` fullScreenCover — reset `activeSheet` back to `nil` in the same update cycle, cancelling the results presentation and returning the user to the daily tips screen instead.

**`DailyCheckView.swift`**
- Removed `dismiss()` call from `advanceOrFinish()`. Changing `activeSheet` from `.dailyCheck` to `.results` inside the `onFinished` callback is sufficient — `fullScreenCover(item:)` automatically dismisses the current cover and presents the new one when the item changes.

**Android** — no change required. `DailyCheckScreen` already navigates correctly: `LaunchedEffect(quizFinished) { if (quizFinished) onFinished() }` → `onFinished = { screen = Screen.RESULTS }` in `MainActivity`.

---

### Bug Fix — Daily Tips Repeating Across Days (iOS & Android)

**Root cause:** `todayTips` was computed once on ViewModel/app init and never refreshed when the app returned from the background. SwiftUI's `onAppear` does not fire on foreground resume, and Android's ViewModel `init` block runs only once per process. Users who kept the app in the background overnight and opened it via a daily notification would see the previous day's 5 tips.

**iOS — `DailyPackView.swift`**
- Extracted the refresh logic (`DailyPackProgressManager.resetIfNewDay()`, `viewModel.refreshTodayTips()`, `index` guard, score re-read, fade animation) into a private `refreshForCurrentDay()` helper.
- `onAppear` now calls `refreshForCurrentDay()`.
- Added `.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification))` that also calls `refreshForCurrentDay()`, ensuring today's tips are loaded every time the user opens the app from a notification or app switcher on a new day.

**Android — `CJISViewModel.kt`**
- Added `refreshTodayTips()` function: checks if `dailyProgress.dayKey` matches today; if not, resets `DailyPackProgress` to a fresh state (persisted to DataStore) and reloads `_todayTips` from `DataRepository`.

**Android — `DailyPackScreen.kt`**
- Added `DisposableEffect` with a `LifecycleEventObserver` that calls `viewModel.refreshTodayTips()` and resets `currentTipIndex = 0` on every `ON_RESUME` event — covers both cold launch and background resume.

---

## 2026-03-12

### Android — Icon & Splash Screen Fix

**`res/mipmap-anydpi-v26/ic_launcher.xml` & `ic_launcher_round.xml`**
- Changed adaptive icon to use `@mipmap/ic_launcher_foreground` as the *background* layer and `@android:color/transparent` as the *foreground*. Using the full composited PNG as a foreground layer on top of a matching blue background caused the artwork to be invisible (solid blue circle). Moving it to the background layer means the launcher clips the full PNG directly to the icon shape, making the laptop graphic and orange "CJIS" text visible.

**`gradle/libs.versions.toml` & `app/build.gradle.kts`**
- Added `androidx.core:core-splashscreen:1.0.1` dependency.

**`res/values/themes.xml`**
- Added `Theme.CJISDaily.Splash` extending `Theme.SplashScreen` with dark navy background (`#0D2E6E`) matching the iOS launch screen.

**`res/values/colors.xml`**
- Added `splash_background` color `#0D2E6E`.

**`AndroidManifest.xml`**
- Changed application theme to `Theme.CJISDaily.Splash` so the splash screen activates on launch.

**`MainActivity.kt`**
- Added `installSplashScreen()` call before `super.onCreate()`.

### Android — Icon Fix

**`res/mipmap-anydpi-v26/ic_launcher.xml` & `ic_launcher_round.xml`**
- Fixed AAPT2 build error (`ResourceDirectoryParseException: Failed file name validation`) caused by invalid adaptive icon XML (background referenced a mipmap drawable, foreground referenced `@android:color/transparent`).
- Reverted both files to valid format: `background = @color/ic_launcher_background`, `foreground = @mipmap/ic_launcher_foreground`.

**`res/mipmap-*/ic_launcher_foreground.png`** (all densities)
- Regenerated from correct iOS source: `AppIcon.appiconset/Icon-marketing-1024x1024.png` (laptop/monitor graphic with orange "CJIS" text on blue background) — replaces the previous source that rendered as solid blue.

**`res/mipmap-*/ic_launcher.png` & `ic_launcher_round.png`** (all densities)
- Regenerated from same correct iOS source for pre-API-26 devices.

---

## 2026-03-11

### Android — Stability Pass

**`gradle/libs.versions.toml`**
- Updated `coroutines` from `1.8.1` → `1.9.0` for Kotlin 2.2.x compatibility.

**`ui/screens/DailyPackScreen.kt`**
- Fixed layout bug: moved `Modifier.weight(1f)` from the inner `Column` (inside `AnimatedContent`) to `AnimatedContent` itself. The `weight` modifier is only honored by direct `Column`/`Row` children; applied inside `AnimatedContent`'s internal `Box` it was silently ignored, causing the scrollable tip area to not expand and the bottom nav bar to be pushed off-screen. Inner `Column` now uses `fillMaxSize()`.

**`ui/screens/ResultsScreen.kt`**
- Fixed layout bug: replaced two `HorizontalDivider` calls used as visual separators inside a `Row` with `VerticalDivider`. A `HorizontalDivider` inside a `Row` draws a full-width horizontal line and consumes all remaining horizontal space, collapsing sibling columns. Updated import accordingly.

### Android — Initial Release Build

**New Platform: Android (Kotlin / Jetpack Compose)**
- Created full Android project at `Android/Project/` targeting API 26+ (Android 8.0), compiled against API 35.
- Package ID matches iOS: `com.refuge.cjisdaily`.

**`app/build.gradle.kts` + `gradle/libs.versions.toml`**
- Configured AGP 8.5.2, Kotlin 2.0.21, Compose BOM 2024.09.03, Material3.
- Dependencies: WorkManager, DataStore Preferences, Gson, Coroutines, Material Icons Extended.

**`data/Models.kt`**
- `CjisTip`, `QuizQuestion`, `TipQuizSet`, `DailyScore`, `QuizProgress`, `DailyPackProgress` — direct Kotlin equivalents of iOS Swift models.

**`data/DataRepository.kt`**
- Loads `cjis_tips.json` and `cjis_quizzes.json` from `res/raw/` via Gson.
- `tipsForToday()` uses the same deterministic day-of-year rotation algorithm as iOS.
- Both JSON files copied from iOS project.

**`viewmodel/CJISViewModel.kt`**
- Replaces iOS `AppViewModel` + progress managers with a single `ViewModel` + `StateFlow`.
- DataStore Preferences replaces `UserDefaults` for dark mode, reminder time, quiz progress, and daily pack progress.
- Full quiz state machine: `startDailyCheck()`, `selectAnswer()`, `submitAnswer()`, `nextQuestion()`, `finishQuiz()`.
- Streak and lifetime accuracy tracking with same double-count prevention as iOS (key-gated by day string).

**`ui/screens/DailyPackScreen.kt`**
- 5-tip daily pack with animated tip transitions, progress dots, expandable long text, and back/next navigation.
- Shows "Start Daily Check" or "View Results" + "Completed for today" based on `DailyPackProgress`.

**`ui/screens/DailyCheckScreen.kt`**
- 5-question daily quiz with `AnswerOptionButton` state machine (NORMAL / SELECTED / CORRECT / WRONG / DISABLED).
- Per-question explanation revealed after submission; live score counter in footer.

**`ui/screens/ResultsScreen.kt`**
- Displays today's score, lifetime correct/answered, lifetime accuracy %, and streak count.

**`ui/screens/SettingsScreen.kt`**
- Dark/light mode toggle with `Switch`.
- Material3 `TimePicker` for daily reminder time with "Save Reminder" button.
- About card with app description.

**`ui/components/AnswerOptionButton.kt`**
- Stateful answer button with circular indicator, check/X icons, and border color keyed to `AnswerState` enum.

**`ui/theme/`**
- `Color.kt`: CJIS Blue `#1C5CA1`, parchment light background, deep charcoal dark background, CorrectGreen, WrongRed.
- `Theme.kt`: `CJISDailyTheme` with explicit light/dark `ColorScheme`; theme driven by `isDarkMode` StateFlow (not system default).
- `Type.kt`: Serif headings, sans-serif body/labels — mirrors iOS typography scale.

**`notifications/DailyReminderWorker.kt`**
- `PeriodicWorkRequest` fires daily at user-set time. Initial delay calculated to next target time.
- Creates `NotificationChannel` on first run; uses `ExistingPeriodicWorkPolicy.UPDATE` to reschedule cleanly.

**`notifications/BootReceiver.kt`**
- Restores WorkManager schedule after device reboot by reading saved hour/minute from DataStore.

**`MainActivity.kt`**
- Added runtime `POST_NOTIFICATIONS` permission request for Android 13+ (API 33+).
- `AnimatedContent`-based screen router with no Navigation library needed (4 screens: PACK, QUIZ, RESULTS, SETTINGS).

**`AndroidManifest.xml`**
- Permissions: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`.
- `BootReceiver` registered for `BOOT_COMPLETED`.

**`res/mipmap-*/`**
- App icons generated from iOS 1024×1024 marketing icon, resized to all Android mipmap densities (mdpi 48px → xxxhdpi 192px).
- Adaptive icon XML (`mipmap-anydpi-v26/`) with CJIS Blue background.

**`gradle/wrapper/gradle-wrapper.properties`**
- Added wrapper pointing to Gradle 8.7.

---

## 2026-03-10

### Bug Fixes

**`CJIS Daily.xcodeproj/project.pbxproj`**
- Fixed test target source wiring by adding filesystem-synced groups for `CJIS DailyTests` and `CJIS DailyUITests`, so test bundles include compiled test executables correctly.
- Aligned deployment targets for project and test targets to `15.6` (removed `26.1` mismatch that could block simulator/device test runs).

**`NotificationManager.swift` + `AppViewModel.swift`**
- Changed daily reminder scheduling to use a neutral notification body (`"Open CJIS Daily for today's tip."`) instead of a static tip title, preventing stale repeated content.
- Limited pending-notification removal to the app’s own identifier (`dailyCJISTip`) instead of removing all pending notifications.

**`DailyPackProgressManager.swift` + `DailyPackView.swift`**
- Removed dead daily-pack state (`viewedTipIds`) and the unused `markViewed` flow to reduce unnecessary persistence churn.

### Maintenance

**Tests Added**
- Added missing baseline test files:
  - `iOS/CJIS DailyTests/CJIS_DailyTests.swift`
  - `iOS/CJIS DailyUITests/CJIS_DailyUITests.swift`
  - `iOS/CJIS DailyUITests/CJIS_DailyUITestsLaunchTests.swift`

**Repository Cleanup**
- Removed non-runtime artifacts that should not ship in source:
  - `iOS/CJIS Daily/CJIS.psd`
  - `Archive/CJIS Daily.app/*`

---

## 2026-03-09

### Bug Fixes

**`QuizProgressManager.swift`**
- Replaced double `persist()` call in `recordDailyCheckIfNeeded()` with batched logic — all state mutations (streak + lifetime score) now complete in a single atomic write. Previously a crash between the two writes could leave streak updated but lifetime score unrecorded, causing a double-count on next launch.
- Added state validation after UserDefaults decode — guards that `streakCount >= 0`, `lifetimeCorrect >= 0`, `lifetimeAnswered >= 0`, and `lifetimeCorrect <= lifetimeAnswered`. Corrupted or tampered UserDefaults now resets to a clean state instead of propagating invalid values.
- Removed dead `recordLifetimeScoreIfNeeded()` private method — logic was already inlined into `recordDailyCheckIfNeeded()` during the atomic-write refactor, making the method unreachable.

**`AppViewModel.swift`**
- Changed `saveNotificationTime()` from silent `try?` to a `do-catch` with error logging. Previously the UI showed success even if the UserDefaults save failed.

**`TipStore.swift`**
- Replaced O(n²) duplicate check (`results.contains(where:)` inside a loop) with a `Set<Int>` for O(1) lookups. Algorithm now runs in O(n) instead of O(n²).

**`DailyResultsView.swift`**
- Added `.rounded()` before `Int()` conversion on both percentage calculations. Previously `Int()` truncated — 66.6% displayed as 66% instead of 67%.

**`DailyCheckView.swift`**
- Fixed misleading question counter — previously showed "1/1" when `questions` array was empty due to `max(..., 1)` guard. Now shows "0/0" for the empty case.

**`QuizQuestion.swift`**
- Replaced both `precondition` calls in `init(from decoder:)` with `guard + throw` using `DecodingError.dataCorruptedError`. In Release builds `precondition` is stripped — bad JSON data now throws during decoding and is caught by `DailyQuizStore`'s existing `do-catch`, preventing corrupt state from propagating.

**`NotificationManager.swift`**
- Moved `guard let tip` check before `removeAllPendingNotificationRequests()`. Previously if no tip was available, all pending notifications were wiped and nothing rescheduled — silently. Existing schedule is now preserved when no tip is available.
- Added `getNotificationSettings` check before scheduling. If the user revoked notification permission in iOS Settings, the scheduler now skips gracefully with a log warning instead of silently failing when `center.add()` rejects the request.

**`DailyPackProgressManager.swift`**
- Removed redundant `resetIfNewDay()` calls from `isDailyCheckCompleted` and `todaysScore` computed properties. These were accessed on every render pass, triggering unnecessary UserDefaults reads. The reset is already handled in `onAppear`.

**`DailyPackView.swift`**
- Replaced two chained `.fullScreenCover(isPresented:)` modifiers with a single `.fullScreenCover(item:)` driven by an `ActiveSheet` enum (`dailyCheck`, `results`). Stacking two `fullScreenCover` on the same view is a known iOS bug source where the second presenter can fail to trigger or interfere with dismissal.
- Fixed double read of `DailyPackProgressManager.shared.todaysScore` in the results case — replaced with a single `let score = todaysScore ?? DailyPackProgressManager.shared.todaysScore` to read shared state once.

### Performance

**`QuizProgressManager.swift`**
- Replaced inline `DateFormatter` creation inside `dayKey(for:)` with a static lazy instance. `DateFormatter` is expensive to allocate — now created once and reused.

**`DailyPackProgressManager.swift`**
- Same static `DateFormatter` optimization applied.

### Accessibility

**`SettingsView.swift`**
- Added `.accessibilityLabel("Close settings")` to the close (×) button.
- Added `.accessibilityLabel("Select notification time")` to the DatePicker.
- Increased close button touch target to minimum 44×44pt (`minWidth: 44, minHeight: 44`).
- Added Privacy Policy link to the About card (opens `https://www.copanostudios.com/privacy-cjis-daily`). URL uses safe `if let` unwrap instead of force-unwrap.

**`AnswerOptionButton.swift`**
- Added dynamic `.accessibilityLabel` and `.accessibilityHint` based on answer state. VoiceOver now announces "Correct answer", "Incorrect answer", "Selected", or "Double tap to select" as appropriate.

**`DailyCheckView.swift`**
- Added `.accessibilityLabel` to the progress counter — VoiceOver now reads "Question 2 of 5" instead of "2/5".

**`DailyResultsView.swift`**
- Added `.accessibilityLabel("Today's accuracy: X%")` and `.accessibilityLabel("Lifetime accuracy: X%")` to both percentage displays.

**`DailyPackView.swift`**
- Added `.accessibilityLabel("Settings")` to the gear icon button.
- Increased gear button touch target to minimum 44×44pt.

---

## Previous

- Initial app build and content population.
