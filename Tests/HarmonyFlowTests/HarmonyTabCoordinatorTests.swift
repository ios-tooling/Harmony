//
//  HarmonyTabCoordinatorTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Testing
import SwiftUI
@testable import HarmonyFlow

enum TestTab: String, HarmonyTab, Codable {
	case home, profile

	var rootScreen: any HarmonyDestination {
		switch self {
		case .home: TestScreen.home
		case .profile: TestScreen.settings
		}
	}

	var label: some View { Text(rawValue) }
}

@MainActor
struct HarmonyTabCoordinatorTests {
	@Test func eachTabKeepsItsOwnStack() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).push(TestScreen.detail)
		#expect(tabs.coordinator(for: .home).fullPath == [.detail])
		#expect(tabs.coordinator(for: .profile).fullPath.isEmpty)
	}

	@Test func tabCoordinatorsAreStable() {
		// per-tab navigation state survives tab switches because the same
		// coordinator instance is always returned
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let profile = tabs.coordinator(for: .profile)
		tabs.selectedTab = .profile
		tabs.selectedTab = .home
		#expect(tabs.coordinator(for: .profile) === profile)
	}

	@Test func showInTabSwitchesAndPushes() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.show(TestScreen.detail, in: .profile)
		#expect(tabs.selectedTab == .profile)
		#expect(tabs.coordinator(for: .profile).fullPath == [.detail])
	}

	@Test func showInTabHonorsPresentationConfig() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.show(TestScreen.detail, in: .profile, config: .init(action: .partialModal))
		#expect(tabs.selectedTab == .profile)
		#expect(tabs.coordinator(for: .profile).sheetCoordinator?.root == .detail)
	}

	@Test func tabBottomSheetsHoistToTabCoordinator() {
		// bottom sheets render above the tab bar, so the tab coordinator hosts them
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		#expect(tabs.bottomSheetCoordinator?.root == .detail)
		#expect(tabs.coordinator(for: .home).bottomSheetCoordinator == nil)
	}

	@Test func tabBottomSheetsReplaceAcrossTabs() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		let first = tabs.bottomSheetCoordinator
		tabs.coordinator(for: .profile).bottomSheet(TestScreen.settings)
		#expect(tabs.bottomSheetCoordinator !== first)
		#expect(tabs.bottomSheetCoordinator?.root == .settings)
	}

	@Test func tabBottomSheetDismissStackClearsTabSlot() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		tabs.bottomSheetCoordinator?.dismissStack()
		#expect(tabs.bottomSheetCoordinator == nil)
	}

	@Test func modalBottomSheetsStayInTheirModal() {
		// a bottom sheet inside a modal belongs to the modal (which covers the tab
		// bar anyway), not to the tab-level layer
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).partialModal(TestScreen.settings)
		tabs.coordinator(for: .home).modalCoordinator?.bottomSheet(TestScreen.detail)
		#expect(tabs.coordinator(for: .home).modalCoordinator?.bottomSheetCoordinator?.root == .detail)
		#expect(tabs.bottomSheetCoordinator == nil)
	}

	@Test func bottomSheetFromTabLevelSheetReplacesIt() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).bottomSheet(TestScreen.detail)
		let first = tabs.bottomSheetCoordinator
		first?.bottomSheet(TestScreen.settings)
		#expect(tabs.bottomSheetCoordinator !== first)
		#expect(tabs.bottomSheetCoordinator?.root == .settings)
	}

	@Test func collapseReturnsSelectedTabToItsRoot() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .home).push(TestScreen.detail)
		tabs.coordinator(for: .home).partialModal(TestScreen.settings)
		tabs.collapse()
		#expect(tabs.coordinator(for: .home).fullPath.isEmpty)
		#expect(tabs.coordinator(for: .home).modalCoordinator == nil)
	}

	@Test func collapseLeavesOtherTabsAlone() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		tabs.coordinator(for: .profile).push(TestScreen.detail)
		tabs.coordinator(for: .home).push(TestScreen.detail)
		tabs.collapse(.home)
		#expect(tabs.coordinator(for: .home).fullPath.isEmpty)
		#expect(tabs.coordinator(for: .profile).fullPath == [.detail])
	}

	@Test func plainCoordinatorsHostTheirOwnBottomSheets() {
		// standalone coordinators (e.g. inside a vanilla TabView) keep bottom sheets
		// local — no tab coordinator required
		let one = HarmonyCoordinator(TestScreen.home)
		let two = HarmonyCoordinator(TestScreen.settings)
		one.bottomSheet(TestScreen.detail)
		#expect(one.bottomSheetCoordinator?.root == .detail)
		#expect(two.bottomSheetCoordinator == nil)
	}
}
