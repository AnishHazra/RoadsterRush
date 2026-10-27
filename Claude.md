# Pile — CLAUDE.md

## Project

- This is a native iOS app built with Swift + SwiftUI.
- Follow Feature-Based Architecture with MVVM.
- Keep everything simple, readable, and beginner-friendly.

## Rules

### 1. Comments — keep them minimal (most important)

- Do NOT write long comment blocks, essays, or multi-paragraph doc comments.
- Add a comment only when the _why_ is not obvious from the code. One short line, max two.
- No comments that just restate what the code does (`// set the title`, `// call API`).
- No change-history comments (`// changed X to Y`, `// used to be…`, `// fixed bug`, `// new`). That belongs in the commit message.
- No commented-out code. Delete it.
- Follow the comment style of the file you are editing; if it has few comments, add few.

```swift
// ❌ Don't
/// The shadow under the coin. Cast onto the screen rather than turning with the coin: it
/// slides away from the light and spreads as the coin comes side-on, which is most of
/// what sells the near edge as nearer, and it used to be applied before the rotation…
// ✅ Do
// Stays on screen instead of rotating with the coin
```

### 2. Git

- Do not commit or push unless asked. Branch off `develop`, never commit to it directly.
- Commit message is a single subject line only: `type(Scope): summary` (e.g. `feat(Badge): add sponsored badges`). No description body.
- Never add `Co-Authored-By: Claude …` or any other Claude attribution to commits or PRs.

## Deployment Target

- Minimum deployment target is iOS 17.
- Gate newer APIs (e.g. iOS 26 Liquid Glass, `IntentModes`, `safeAreaBar`) with `if #available(iOS 26, *)` or `@available(iOS 26.0, *)`, and always provide an iOS 17 fallback.
- Reuse the existing wrappers instead of calling iOS 26 APIs directly: `.glassButtonStyle(prominent:)`, `.glassCapsule()`, `.pinnedBar(edge:)`, `.navigationSubtitleIfAvailable(_:)`, `CloseButton`, `CancelButton`, `ConfirmButton`.

```swift
static let openAppWhenRun = true

@available(iOS 26.0, *)
static var supportedModes: IntentModes { .foreground }
```

## Language Conventions

- Prefer async/await for asynchronous code.
- Avoid DispatchQueue for new code.
- MVVM architecture: View → ViewModel (ObservableObject) → Service → Repository
- No force unwrap (`!`) — use guard let, if let, or nil coalescing

# Resources

- Keep reusable colors, fonts, and assets inside `Resources/`.
- Use `AppColors`, `AppFonts`, for shared resources.
- Do not hardcode colors, fonts, or asset names inside Views.
- Reuse existing resources whenever possible.

```
Resources/
├── AppColors.swift
├── AppFonts.swift
└── Assets.xcassets
```

## Architecture Rules

- ViewModels must not import SwiftUI (business logic only)
- No business logic in View files
- Separate files for each View, ViewModel, Service (1 type per file rule)

Organize code by **feature**, not by file type.

Example:

```text
App/
├── AppNameApp.swift
│
├── Core/
│   ├── Authentication/
│   ├── Home/
│   ├── Profile/
│   ├── Settings/
│   └── ...
│
├── Components/
├── Services/
├── Models/
├── Extensions/
└── Utils/
```

## SwiftUI Patterns

- `@State` for local UI state only (never business state)
- `@StateObject` for ViewModels owned by the view
- `@ObservedObject` for ViewModels passed in from a parent
- `@EnvironmentObject` for app-wide state (inject at root)
- Keep View bodies simple and readable.
- Extract subviews when a View becomes difficult to understand.

## Swift Concurrency Rules

- Prefer `async/await`.
- Avoid advanced concurrency features unless required.
- `@MainActor` annotation required on ViewModels and any class that updates UI
- Use `Task { }` to bridge sync to async contexts, not `DispatchQueue.main.async`
- Avoid `nonisolated` unless Swift requires it.
- Do not introduce advanced concurrency concepts unnecessarily.

## Memory Management

### Retain cycles

- Use `[weak self]` in every closure that is stored or outlives the call: Combine `.sink`, stored `Task` properties, and callbacks handed to services.
- Store Combine subscriptions in `private var cancellables = Set<AnyCancellable>()`.
- For fire-and-forget tasks, capture only the dependencies you need, not `self`: `Task { [speechService] in await speechService.stop() }`.
- Callbacks coming from audio or background threads hop back with `Task { @MainActor [weak self] in self?.… }`.
- Before replacing a stored `Task`, cancel the old one: `releaseTask?.cancel()`.
- Services must never hold a strong reference to a ViewModel. Delegates and coordinators must not capture their owner strongly.
- Build audio tap blocks and recognizer handlers in `nonisolated static` functions so they can't capture `self`.

```swift
DataChanges.publisher
    .sink { [weak self] in self?.reload() }
    .store(in: &cancellables)

releaseTask?.cancel()
releaseTask = Task { [weak self] in
    do {
        try await Task.sleep(for: .seconds(1))
    } catch {
        return
    }
    self?.reload()
}
```

### Mic, audio and other resources

- Every `start` needs a matching `stop` on **every** path, including when it throws. If the engine fails to start, remove the tap and release the audio session before rethrowing.
- Stop recording, dictation and playback in `onDisappear` (through the ViewModel's `cancel()` or `finish()`).
- A view can close while an `await` is pending, like a permission prompt or an engine start. After each `await`, check a flag (`isClosed`, `isStartingDictation`) and stop straight away if the screen is gone.
- Delete leftover recording files when a recording fails or is cancelled.
- Guard against starting twice (`guard startedAt == nil`, `guard cancellables.isEmpty`).

```swift
try await speechService.start(...)
guard !isClosed else {
    await speechService.stop()
    deleteRecording(at: url)
    return
}
```

### Views

- Prefer `.task {}` / `.task(id:)` over `Task {}` in `onAppear`, since SwiftUI cancels it when the view goes away.
- Only show `TimelineView(.animation)` while it is needed, or pass `paused:` so it doesn't redraw forever.

# Swift Package Manager

- Use Swift Package Manager (SPM) for third-party dependencies.
- Prefer SPM over manually added frameworks.
- Do not add a package unless it is actually needed.

## Error Handling

- Never use:

```

catch {
}

```

- Always handle errors properly.

- Example:

```

do {
try await repository.saveUser(user)
} catch {
logger.error("Failed to save user: \(error.localizedDescription)")
}

```

# ViewModifiers

- Use custom `ViewModifier`s for reusable UI styles or behavior.
- Keep reusable ViewModifiers inside `Utils/ViewModifiers/`.
- Keep them simple and focused.
- Do not put business logic inside ViewModifiers.

# iOS Widgets

- Use `WidgetKit` for iOS Home Screen and Lock Screen widgets.
- Keep widgets in a separate `Widgets/` target/folder.
- Keep widget code simple and focused on displaying data.
- Do not put business logic inside widgets.
- Reuse shared models and resources when possible.

```
Widgets/
├── AppWidget.swift
├── AppWidgetEntry.swift
└── AppWidgetProvider.swift
```

# Tests

- Do not write test cases or add test files.
- Do not add a test target (unit or UI) to the Xcode project.

# Simulator

- Do not run or launch the app on the iOS Simulator.
- Do not start the Simulator to verify changes.
- Only build/check the code if needed.
- Stop after the code is successfully built.
- I will run and test the app manually.
