# HarmonyFlow

Unified, coordinator-driven navigation for SwiftUI on iOS and macOS. Each feature defines its own screen types; lightweight coordinators own the navigation state; container views (`HarmonyStack`, `HarmonyTabs`, `HarmonySplit`) render it. Pushes, modals, bottom sheets, tabs, split views, async "present-for-result", and opt-in state restoration all speak the same vocabulary.

- **Requirements:** iOS 18+, macOS 15+, Swift 6
- **No UIKit fallbacks**, no hard-coded dimensions, `async/await` throughout.

## Installation

```swift
.package(url: "https://github.com/ios-tooling/HarmonyFlow.git", branch: "main")
```

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "HarmonyFlow", package: "HarmonyFlow")
])
```

Import it as `import HarmonyFlow`. (No versioned release is tagged yet; pin to a commit if you need stability.)

## The core idea

You define screen types by conforming to **`HarmonyDestination`** — typically one enum per feature/framework. Each case knows how to draw itself, given a coordinator. The framework boxes any destination into a single concrete `HarmonyScreen` value, so destinations from **different, independent frameworks coexist in the same coordinator/stack** — there is no central enum that has to know them all.

```swift
enum Screen: HarmonyDestination {
    case home, detail, settings

    var id: String { "\(self)" }

    func body(configuration: HarmonyScreenConfiguration) -> some View {
        switch self {
        case .home:
            Button("Show detail") { configuration.coordinator.push(Screen.detail) }
        case .detail:
            Button("Settings") { configuration.coordinator.partialModal(Screen.settings) }
        case .settings:
            Button("Done") { configuration.coordinator.dismiss() }
        }
    }
}
```

> **Note on shorthand:** navigation methods take `any HarmonyDestination`, so leading-dot syntax (`push(.detail)`) can't infer the type — qualify the case name (`push(Screen.detail)`).

Create a coordinator with a root screen and hand it to a `HarmonyStack`:

```swift
struct ContentView: View {
    @State private var coordinator = HarmonyCoordinator(Screen.home)
    var body: some View { HarmonyStack(coordinator) }
}
```

## Reaching the coordinator

Every screen `body` receives a `HarmonyScreenConfiguration` with `.coordinator`. Deeper subviews can pull the same coordinator from the environment instead of threading it down — the coordinator is a single non-generic type, so a view in *any* framework can reach it without naming an app-specific screen type:

```swift
struct DeepButton: View {
    @HarmonyCoordinated private var coordinator
    var body: some View { Button("Back") { coordinator.dismiss() } }
}
```

`@HarmonyCoordinated` traps if no coordinator is in the environment; use its projected value (`$coordinator`) for optional access (e.g. a standalone `#Preview`). The underlying `@Environment(HarmonyCoordinator.self)` works too.

## Modular apps & multiple frameworks

Because the coordinator tree is built on the erased `HarmonyScreen`, a feature framework imports **only HarmonyFlow** and defines its own destinations; it never imports its siblings. Any screen can push or present any other:

```swift
// in ProfileKit — knows nothing about other features
coordinator.push(ProfileScreen.editor)
coordinator.push(Screen.settings)   // a different framework's type, same stack
```

Type erasure solves *coexistence*. Cross-feature *navigation intent* still needs a contract — keep features decoupled by inverting the dependency (inject an `onOpenSettings: () -> Void` the app fills in) or by routing through your **app target as the composition root**, the one place that imports everything and maps routes to concrete screens.

## Navigation vocabulary

```swift
coordinator.push(Screen.detail)            // onto the navigation stack
coordinator.partialModal(Screen.settings)  // sheet, .medium detent by default
coordinator.bottomSheet(Screen.filters)    // interactive overlay card (see below)
coordinator.fullScreenModal(Screen.editor) // full-screen cover (sheet on macOS)

coordinator.dismiss()              // go back one: pop a push, or dismiss a presentation root
coordinator.dismissStack()         // dismiss the entire presented flow this screen lives in
coordinator.pop(to: Screen.home)   // pop back to a specific screen
coordinator.popToRoot()            // pop all pushes
coordinator.collapse()             // back to a pristine root: pop everything + drop presentations
```

`dismiss()` is always "go back one step" — a screen never needs to know *how* it was presented.

## Per-presentation configuration

`show(_:config:)` is the general form; the helpers above are shorthands for it. Configure detents and dismissal per presentation:

```swift
coordinator.show(Screen.filters, config: .init(
    action: .bottomSheet,
    detents: [.fraction(0.25), .medium, .fraction(0.85)],
    isInteractiveDismissDisabled: true
))
```

`HarmonyDetent` (`.medium`, `.large`, `.fraction(_)`, `.height(_)`) is platform-neutral — it maps to `PresentationDetent` on iOS and is honored by HarmonyFlow's own bottom-sheet renderer on both platforms.

## Bottom sheets

Bottom sheets are **not** system sheets — they're draggable overlay cards rendered by HarmonyFlow, so the content behind them stays fully interactive (Maps / Apple Music style) and they persist while modals appear over them. Rules:

- A bottom sheet attaches to its **presentation context** (its stack, modal, or — under tabs — the tab bar layer), rendering above that context's chrome.
- There is **one** bottom sheet per context; presenting a new one replaces the old. Bottom sheets never stack on each other.
- Tapping the dimmed scrim dismisses the sheet (unless `isInteractiveDismissDisabled` is set).

## Present-for-result

Modal flows can return a value with `async/await`. Any dismissal that doesn't call `finish` (swipe, `dismiss()`, replacement, or a dismissed parent flow) resumes the caller with `nil`:

```swift
// presenter
let picked: Color? = await coordinator.present(ColorPickerScreen.picker)

// inside the presented screen
configuration.coordinator.finish(returning: chosenColor)
```

The result type is fixed at the call site (erasure means it can't be tied to the screen statically); a type mismatch resolves to `nil`.

## Tabs

Conform a tab enum to `HarmonyTab` (each case supplies a `rootScreen` and a `label`), then drive it with `HarmonyTabs`:

```swift
enum AppTab: HarmonyTab {
    case home, settings
    var rootScreen: any HarmonyDestination { self == .home ? Screen.home : Screen.settings }
    var label: some View {
        switch self {
        case .home: Label("Home", systemImage: "house")
        case .settings: Label("Settings", systemImage: "gear")
        }
    }
}

struct RootView: View {
    @State private var tabs = HarmonyTabCoordinator(selected: AppTab.home)
    var body: some View { HarmonyTabs(tabs) }
}
```

Each tab keeps its own navigation stack across switches. Navigate across tabs from anywhere via `@Environment(HarmonyTabCoordinator<AppTab>.self)`:

```swift
tabs.show(Screen.account, in: .settings)   // switch tab, then push
tabs.collapse()                            // reset the selected tab to its root
tabs.isTabBarHidden = true                 // animated hide/show (iOS)
```

## Split views

`HarmonySplitCoordinator` backs 2- or 3-column layouts; columns navigate independently with the full vocabulary above. Columns may hold destinations of different types.

```swift
let split = HarmonySplitCoordinator(sidebar: Screen.home, detail: Screen.settings)   // add content: for 3 columns
HarmonySplit(split)

split.showDetail(Screen.account)   // selection-style: replaces the detail column's stack
```

## State persistence & deep linking

`HarmonyScreen` is always `Codable`, so the save/restore API is always available. Because destinations are type-erased, persistence needs a way to recover the concrete type on decode: register each `Codable` destination type once (e.g. at launch). Each framework registers its own — no central list.

```swift
HarmonyScreenRegistry.register(Screen.self, forKey: "App.Screen")
HarmonyScreenRegistry.register(ProfileScreen.self, forKey: "Profile.Screen")

let data = try coordinator.encodedState()              // save (whole presentation tree)
let coordinator = try HarmonyCoordinator(restoring: data)   // restore at launch
```

`encodedState()` / `init(restoring:)` work the same on `HarmonyTabCoordinator` and `HarmonySplitCoordinator` (their `Tab` must also be `Codable`). A screen whose type wasn't registered throws on encode/decode — restore paths treat that as "skip".

For deep links, parse the URL into destinations (your code) and hand the path over:

```swift
coordinator.replacePath([Screen.account, Screen.orders, Screen.order(id)])
```

## Accessing container coordinators safely

A screen shared between a tab root and a split root may not have a given container in its environment. Fetch container coordinators **optionally** unless a screen is exclusive to one container:

```swift
@Environment(HarmonyTabCoordinator<AppTab>.self) private var tabs: HarmonyTabCoordinator<AppTab>?
```

The per-`HarmonyStack` `HarmonyCoordinator` is always present, so non-optional access to it (e.g. via `@HarmonyCoordinated`) is safe.

## License

See repository.
