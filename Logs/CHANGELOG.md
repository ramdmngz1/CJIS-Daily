# CJIS Daily — Changelog

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
