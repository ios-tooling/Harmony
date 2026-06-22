//
//  HarmonySplitCoordinatorTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Testing
import SwiftUI
@testable import HarmonyFlow

@MainActor
struct HarmonySplitCoordinatorTests {
	@Test func twoColumnSplitHasNoContentColumn() {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, detail: TestScreen.detail)
		#expect(split.contentCoordinator == nil)
		#expect(split.sidebarCoordinator.root == .home)
		#expect(split.detailCoordinator.root == .detail)
	}

	@Test func threeColumnSplitKeepsAllColumns() {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, content: TestScreen.detail, detail: TestScreen.settings)
		#expect(split.contentCoordinator?.root == .detail)
	}

	@Test func showDetailReplacesTheDetailStack() {
		// selection navigation resets the detail column, dropping any pushed screens
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, detail: TestScreen.detail)
		split.detailCoordinator.push(TestScreen.settings)
		split.showDetail(TestScreen.home)
		#expect(split.detailCoordinator.root == .home)
		#expect(split.detailCoordinator.fullPath.isEmpty)
	}

	@Test func columnsNavigateIndependently() {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, detail: TestScreen.detail)
		split.sidebarCoordinator.push(TestScreen.settings)
		#expect(split.detailCoordinator.fullPath.isEmpty)
		split.detailCoordinator.partialModal(TestScreen.settings)
		#expect(split.sidebarCoordinator.modalCoordinator == nil)
	}
}
