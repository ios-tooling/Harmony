//
//  HarmonyPersistenceTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/12/26.
//

import Testing
import Foundation
@testable import HarmonyFlow

@MainActor
struct HarmonyPersistenceTests {
	init() {
		// the registry recovers erased destination types on decode
		HarmonyScreenRegistry.register(TestScreen.self, forKey: "TestScreen")
	}

	@Test func stateRoundTripsThroughData() throws {
		let original = HarmonyCoordinator([TestScreen.home, .detail, .settings])
		let restored = try HarmonyCoordinator(restoring: original.encodedState())
		#expect(restored.root == .home)
		#expect(restored.fullPath == [.detail, .settings])
	}

	@Test func presentedTreeSurvivesRoundTrip() throws {
		// the whole presentation tree persists: children, their paths, and their configs
		let original = HarmonyCoordinator(TestScreen.home)
		original.show(TestScreen.settings, config: .init(action: .partialModal, detents: [.fraction(0.75)], isInteractiveDismissDisabled: true))
		original.sheetCoordinator?.push(TestScreen.detail)

		let restored = try HarmonyCoordinator(restoring: original.encodedState())
		#expect(restored.sheetCoordinator?.root == .settings)
		#expect(restored.sheetCoordinator?.fullPath == [.detail])
		#expect(restored.sheetCoordinator?.configuration.detents == [.fraction(0.75)])
		#expect(restored.sheetCoordinator?.configuration.isInteractiveDismissDisabled == true)
	}

	@Test func restoredChildrenCanDismiss() throws {
		// parent links must be rebuilt, not just the tree shape
		let original = HarmonyCoordinator(TestScreen.home)
		original.bottomSheet(TestScreen.detail)
		let restored = try HarmonyCoordinator(restoring: original.encodedState())
		restored.bottomSheetCoordinator?.dismissStack()
		#expect(restored.bottomSheetCoordinator == nil)
	}

	@Test func replacePathSwapsWholePath() {
		let coordinator = HarmonyCoordinator([TestScreen.home, .detail])
		coordinator.replacePath([TestScreen.settings, .detail, .settings])
		#expect(coordinator.fullPath == [.settings, .detail, .settings])
	}

	@Test func tabStateRoundTrips() throws {
		let tabs = HarmonyTabCoordinator(selected: TestTab.profile)
		tabs.isTabBarHidden = true
		tabs.coordinator(for: .home).push(TestScreen.detail)

		let restored = try HarmonyTabCoordinator<TestTab>(restoring: tabs.encodedState())
		#expect(restored.selectedTab == .profile)
		#expect(restored.isTabBarHidden)
		#expect(restored.coordinator(for: .home).fullPath == [.detail])
		#expect(restored.coordinator(for: .profile).fullPath.isEmpty)
	}

	@Test func tabLevelBottomSheetRoundTripsWithWorkingHostLinks() throws {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)

		let restored = try HarmonyTabCoordinator<TestTab>(restoring: tabs.encodedState())
		#expect(restored.bottomSheetCoordinator?.root == .detail)
		restored.bottomSheetCoordinator?.dismissStack()
		#expect(restored.bottomSheetCoordinator == nil)
	}

	@Test func splitStateRoundTrips() throws {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, content: TestScreen.detail, detail: TestScreen.settings)
		split.sidebarCoordinator.push(TestScreen.settings)
		split.detailCoordinator.push(TestScreen.detail)

		let restored = try HarmonySplitCoordinator(restoring: split.encodedState())
		#expect(restored.sidebarCoordinator.fullPath == [.settings])
		#expect(restored.contentCoordinator?.root == .detail)
		#expect(restored.detailCoordinator.root == .settings)
		#expect(restored.detailCoordinator.fullPath == [.detail])
	}
}
