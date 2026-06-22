//
//  HarmonyCoordinatorTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/10/26.
//

import Testing
import SwiftUI
@testable import HarmonyFlow

enum TestScreen: String, HarmonyDestination, Codable {
	case home, detail, settings

	var id: String { rawValue }

	func body(configuration: HarmonyScreenConfiguration) -> some View {
		VStack {
			Text(rawValue)
			EnvironmentProbe()
		}
	}
}

// test ergonomics: compare erased HarmonyScreen values against raw TestScreen cases
// so assertions read the same as before the type-erasure refactor
func == (lhs: HarmonyScreen, rhs: TestScreen) -> Bool { lhs.destination as? TestScreen == rhs }
func == (lhs: HarmonyScreen?, rhs: TestScreen) -> Bool { lhs?.destination as? TestScreen == rhs }
func == (lhs: [HarmonyScreen], rhs: [TestScreen]) -> Bool {
	lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { ($0.destination as? TestScreen) == $1 }
}
func == (lhs: [HarmonyScreen]?, rhs: [TestScreen]) -> Bool {
	guard let lhs else { return false }
	return lhs == rhs
}

// mirrors how real apps reach the coordinator from nested views; rendering this
// traps if HarmonyStack ever fails to inject the coordinator into the environment
struct EnvironmentProbe: View {
	@Environment(HarmonyCoordinator.self) private var coordinator

	var body: some View {
		Text("depth \(coordinator.fullPath.count)")
	}
}

@MainActor
struct HarmonyCoordinatorTests {
	@Test func coordinatorsHaveDistinctIDs() {
		// sheet(item:) keys presentation identity off `id`; duplicate ids break re-presentation
		let a = HarmonyCoordinator(TestScreen.home)
		let b = HarmonyCoordinator(TestScreen.home)
		#expect(a.id != b.id)
	}

	@Test func pushAppendsToPath() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.push(TestScreen.detail)
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func pathBindingRecordsExternalPushes() {
		// NavigationLink(value:) writes through the binding; the coordinator must not revert it
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.pathBinding.wrappedValue.append(HarmonyScreen(TestScreen.detail))
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func pathBindingPopsScreens() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail, .settings])
		coordinator.pathBinding.wrappedValue.removeLast()
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func partialModalCreatesSheetChild() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.partialModal(TestScreen.settings)
		#expect(coordinator.sheetCoordinator?.root == .settings)
		#expect(coordinator.fullScreenCoordinator == nil)
		#expect(coordinator.fullPath.isEmpty)
	}

	@Test func fullScreenModalCreatesFullScreenChild() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.fullScreenModal(TestScreen.settings)
		#if os(iOS)
		#expect(coordinator.fullScreenCoordinator?.root == .settings)
		#expect(coordinator.sheetCoordinator == nil)
		#else
		// macOS has no full-screen covers; fullScreenModal presents as a sheet
		#expect(coordinator.sheetCoordinator?.root == .settings)
		#expect(coordinator.fullScreenCoordinator == nil)
		#endif
	}

	@Test func popToScreenDropsEverythingAboveIt() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail, .settings, .detail, .settings])
		coordinator.pop(to: TestScreen.detail)
		#expect(coordinator.fullPath == [.detail, .settings, .detail])
	}

	@Test func popToRootScreenClearsThePath() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail, .settings])
		coordinator.pop(to: TestScreen.home)
		#expect(coordinator.fullPath.isEmpty)
	}

	@Test func popToMissingScreenDoesNothing() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail])
		coordinator.pop(to: TestScreen.settings)
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func dismissPopsPushedScreenFirst() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.push(TestScreen.detail)
		coordinator.dismiss()
		#expect(coordinator.fullPath.isEmpty)
	}

	@Test func presentationConfigIsStoredOnPresentedCoordinator() {
		// per-screen presentation options must survive to the child coordinator,
		// where HarmonyStack reads them at presentation time
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.show(TestScreen.settings, config: .init(action: .partialModal, detents: [.fraction(0.75)], isInteractiveDismissDisabled: true))
		#expect(parent.sheetCoordinator?.configuration.detents == [.fraction(0.75)])
		#expect(parent.sheetCoordinator?.configuration.isInteractiveDismissDisabled == true)
	}

	#if os(iOS)
	@Test func detentsFallBackToActionDefaultsWhenUnspecified() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.partialModal(TestScreen.settings)
		#expect(parent.sheetCoordinator?.presentationDetents == [.medium])
	}

	@Test func customDetentsOverrideActionDefaults() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.show(TestScreen.settings, config: .init(action: .partialModal, detents: [.height(200), .large]))
		#expect(parent.sheetCoordinator?.presentationDetents == [.height(200), .large])
	}
	#endif

	@Test func dismissStackRemovesWholePresentedStack() {
		// a screen deep inside a presented flow can close the entire flow,
		// without knowing how it was presented
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.partialModal(TestScreen.settings)
		let sheet = parent.sheetCoordinator
		sheet?.push(TestScreen.detail)
		sheet?.push(TestScreen.home)
		sheet?.dismissStack()
		#expect(parent.sheetCoordinator == nil)
	}

	@Test func dismissStackAtRootDoesNothing() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail])
		coordinator.dismissStack()
		#expect(coordinator.fullPath == [.detail])
	}

	@Test func dismissOnPresentedRootRemovesItFromParent() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(TestScreen.settings)
		parent.bottomSheetCoordinator?.dismiss()
		#expect(parent.bottomSheetCoordinator == nil)
	}

	@Test func sheetBindingNilOnlyClearsSheetChildren() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.fullScreenModal(TestScreen.settings)
		coordinator.sheetCoordinator = nil
		#if os(iOS)
		// SwiftUI writes nil through inactive presentation bindings during updates;
		// a sheet dismissal must not tear down a full-screen child
		#expect(coordinator.fullScreenCoordinator != nil)
		#else
		// on macOS fullScreenModal presents as a sheet, so the sheet binding owns its dismissal
		#expect(coordinator.modalCoordinator == nil)
		#endif
	}

	@Test func fullScreenBindingNilOnlyClearsFullScreenChildren() {
		let coordinator = HarmonyCoordinator(TestScreen.home)
		coordinator.partialModal(TestScreen.settings)
		coordinator.fullScreenCoordinator = nil
		#expect(coordinator.sheetCoordinator != nil)
	}

	@Test func bottomSheetPersistsUnderModal() {
		// a bottom sheet is a persistent layer; presenting a modal must not destroy it
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(TestScreen.detail)
		parent.partialModal(TestScreen.settings)
		#expect(parent.bottomSheetCoordinator?.root == .detail)
		#expect(parent.sheetCoordinator?.root == .settings)
	}

	@Test func modalDismissalLeavesBottomSheetIntact() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(TestScreen.detail)
		parent.partialModal(TestScreen.settings)
		parent.sheetCoordinator = nil
		#expect(parent.bottomSheetCoordinator?.root == .detail)
		#expect(parent.modalCoordinator == nil)
	}

	@Test func bottomSheetsDoNotOccupyTheSheetBinding() {
		// bottom sheets render as overlays, not system sheets; the sheet binding is modal-only
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(TestScreen.detail)
		#expect(parent.sheetCoordinator == nil)
		#expect(parent.bottomSheetCoordinator?.root == .detail)
	}

	@Test func dismissStackClearsOnlyItsOwnSlot() {
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(TestScreen.detail)
		parent.partialModal(TestScreen.settings)
		parent.bottomSheetCoordinator?.dismissStack()
		#expect(parent.bottomSheetCoordinator == nil)
		#expect(parent.sheetCoordinator?.root == .settings)
	}

	@Test func bottomSheetsAttachToTheirPresentationContext() {
		// a bottom sheet presented inside a modal belongs to that modal — it renders
		// above it and travels with it — not to the root
		let root = HarmonyCoordinator(TestScreen.home)
		root.partialModal(TestScreen.settings)
		root.modalCoordinator?.bottomSheet(TestScreen.detail)
		#expect(root.modalCoordinator?.bottomSheetCoordinator?.root == .detail)
		#expect(root.bottomSheetCoordinator == nil)
	}

	@Test func bottomSheetsNeverStackOnBottomSheets() {
		// presenting from inside a bottom sheet bubbles up to its host and replaces it
		let root = HarmonyCoordinator(TestScreen.home)
		root.bottomSheet(TestScreen.detail)
		let first = root.bottomSheetCoordinator
		first?.bottomSheet(TestScreen.settings)
		#expect(root.bottomSheetCoordinator !== first)
		#expect(root.bottomSheetCoordinator?.root == .settings)
		#expect(first?.bottomSheetCoordinator == nil)
	}

	@Test func bottomSheetDismissStackClearsItsHostSlot() {
		let root = HarmonyCoordinator(TestScreen.home)
		root.partialModal(TestScreen.settings)
		root.modalCoordinator?.bottomSheet(TestScreen.detail)
		root.modalCoordinator?.bottomSheetCoordinator?.dismissStack()
		#expect(root.modalCoordinator?.bottomSheetCoordinator == nil)
		#expect(root.modalCoordinator?.root == .settings)
	}

	@Test func fullScreenModalLeavesBottomSheetIntact() {
		// the overlay isn't a system presentation, so a full-screen cover can come and
		// go above it without the two ever conflicting
		let parent = HarmonyCoordinator(TestScreen.home)
		parent.bottomSheet(TestScreen.detail)
		parent.fullScreenModal(TestScreen.settings)
		#expect(parent.bottomSheetCoordinator?.root == .detail)
		#expect(parent.modalCoordinator?.root == .settings)
	}
}
