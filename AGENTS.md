# AGENTS.md — HarmonyFlow

Operational guide for coding agents working in this repository. Read this before changing navigation behavior; the architecture has a few load-bearing invariants that aren't obvious from any single file.

The Swift module / library product / target are all named **`HarmonyFlow`** (`import HarmonyFlow`). The public type names are all `Harmony…` (`HarmonyCoordinator`, `HarmonyScreen`, `HarmonyStack`, …) — only the package/module was renamed, not the types.

## What this package is

A SwiftUI navigation framework for iOS 18+ / macOS 15+. One `HarmonyScreen` enum per consuming app describes all destinations; `@Observable` coordinator classes hold navigation state; container views render it. See `README.md` for the consumer-facing API.

## Build & test

```bash
# macOS (fast; runs from the package root)
swift test

# iOS simulator (Swift Testing; some tests are iOS-gated)
xcodebuild test -scheme HarmonyFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# the example app (its Xcode project lives at HarmonyTestHarness/)
cd HarmonyTestHarness
xcodebuild -scheme HarmonyTestHarness -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Always verify on both platforms** before declaring a navigation change done — behavior legitimately differs (see Platform differences). Run the harness build too when you touch view code; tests don't catch every SwiftUI misuse.

The package depends on `ios-tooling/Suite` and `ios-tooling/chronicle` (resolved from GitHub). `Tab.allCases`, `@Observable`, and Swift Testing are used heavily.

## Repository layout

```
Sources/HarmonyFlow/
  HarmonyScreen.swift                 protocol: one enum per app, draws itself
  HarmonyAction.swift                 push / bottomSheet / partialModal / fullScreenModal (+ iOS detent defaults)
  HarmonyDetent.swift                 platform-neutral detent; maps to PresentationDetent (iOS) + height resolver (both)
  HarmonyNavigationConfiguration.swift per-presentation options (action, detents, interactive dismiss)
  HarmonyStack.swift                  renders a single HarmonyCoordinator (NavigationStack + sheet/cover + bottom-sheet overlay)
  HarmonyBottomSheet.swift            the draggable overlay card (HarmonyFlow-rendered, NOT a system sheet)
  HarmonyBottomSheetHosting.swift     internal protocol; lets a tab coordinator host a stack's bottom sheet
  HarmonyCoordinator/                 the stack coordinator, split across +Show / +Path / +Present / +Persistence
  HarmonyTabs/                        HarmonyTab, HarmonyTabCoordinator (+Persistence), HarmonyTabs view
  HarmonySplit/                       HarmonySplitCoordinator (+Persistence), HarmonySplit view
Tests/HarmonyFlowTests/               Swift Testing suites (incl. rendering smoke tests)
HarmonyTestHarness/                   example app (Xcode project, synchronized folder groups)
```

Conventions (from the owner's global `CLAUDE.md`, enforced here): files ≈100 lines or less — split large types by functionality into `Type+Feature.swift`; no multi-line function declarations; full-screen views named `…Screen`; no UIKit fallbacks in app code; no hard-coded layout dimensions; `async/await` only (no Combine/GCD). Commit messages must not mention LLM assistance. **Never push** unless explicitly asked.

## Load-bearing invariants — do not break these

1. **`removeFromParentCoordinator()` is the single teardown funnel.** Every dismissal path (`dismiss`, `dismissStack`, swipe, replacement, `collapse`) ends here. Two things hang off it: clearing the correct parent slot *by identity*, and resolving a pending present-for-result continuation (via the slot `didSet`s — see #4). If you add a new way to remove a coordinator, route it through here or you'll leak suspended tasks / orphan continuations.

2. **Two child slots, not one.** A coordinator has `modalCoordinator` (partial + full-screen) **and** `bottomSheetCoordinator`. They're separate so a bottom sheet can persist while a modal is presented over it. `sheetCoordinator` / `fullScreenCoordinator` are *computed accessors over `modalCoordinator`* used as SwiftUI presentation bindings — their setters must only clear when written `nil` and only for their own action kind (SwiftUI writes nil through inactive bindings during updates).

3. **Bottom sheets bubble to a host and never stack.** `bottomSheetHost` walks up: a bottom sheet presented from inside a bottom sheet replaces it. Under tabs, `externalBottomSheetHost` redirects a stack's bottom sheet to the `HarmonyTabCoordinator` so it renders above the tab bar. Routing lives in `HarmonyCoordinator.addChild`.

4. **Present-for-result resolves in slot `didSet`.** `modalCoordinator` / `bottomSheetCoordinator` (and the tab coordinator's slot) call `resolvePendingPresentation()` on the *old* value when reassigned. This guarantees exactly-once resumption regardless of how the presentation ended. Don't move continuation resumption into individual dismiss methods — it'll double-resume (crash) or miss paths (leak).

5. **`HarmonyStack` holds its coordinator as a `let`, not `@State`.** Container views (split columns, `showDetail`) swap coordinators out; `@State` would pin the first instance forever. The body uses `@Bindable var coordinator = coordinator` to get presentation bindings.

6. **Coordinators are root-level containers.** `HarmonyTabs` / `HarmonySplit` can't be presented *inside* a `HarmonyStack` (everything there is inside a `NavigationStack`). They're app roots only.

## Platform differences (expected, not bugs)

- **macOS has no `fullScreenCover`** → `fullScreenModal` degrades to a system sheet. `HarmonyAction.isSheet` returns `true` for `fullScreenModal` on macOS, and `fullScreenCoordinator` returns `nil` there. Tests that assert iOS routing are `#if os(iOS)`-gated; the macOS branch asserts the sheet path.
- **`PresentationDetent` is iOS-only.** `HarmonyDetent`'s `presentationDetent` mapping and the action detent defaults are `#if os(iOS)`. The bottom-sheet overlay uses `resolvedHeight(in:)` instead, which works on both.
- **Tab-bar hiding** (`.toolbarVisibility(.hidden, for: .tabBar)`) is iOS-only.

## Persistence pattern

Persistence is **opt-in via conditional conformance** — `extension HarmonyCoordinator where Screen: Codable`, never a protocol requirement. Each coordinator level has a sibling `+Persistence.swift` with a `Snapshot` struct. Recursion through the tree is broken with `[Snapshot]` (0-or-1 element) fields, since structs can't recurse directly. Restoration must **rebuild `parentCoordinator` / `externalBottomSheetHost` links**, not just the tree shape — otherwise restored children can't dismiss. Snapshot-missing tabs deliberately keep the fresh stacks the designated init created (forward-compat with added tab cases).

## Gotchas

- Container coordinators should be fetched from the environment **optionally** in screens shared across container types (a split root has no tab coordinator, and vice-versa). The stack `HarmonyCoordinator` is always present.
- `finish(returning:)` takes `(any Sendable)?` — that's the Swift 6 continuation-crossing requirement, not a design choice.