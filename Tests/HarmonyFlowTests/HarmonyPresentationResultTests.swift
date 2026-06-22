//
//  HarmonyFlowPresentationResultTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Testing
import SwiftUI
@testable import HarmonyFlow

@MainActor
struct HarmonyPresentationResultTests {
	@Test func finishDeliversValueToPresenter() async {
		let parent = HarmonyCoordinator(TestScreen.home)
		async let pending: Int? = parent.present(.settings)
		while parent.sheetCoordinator == nil { await Task.yield() }
		parent.sheetCoordinator?.finish(returning: 42)
		let result = await pending
		#expect(result == 42)
	}

	@Test func plainDismissalResumesWithNil() async {
		let parent = HarmonyCoordinator(TestScreen.home)
		async let pending: Int? = parent.present(.settings)
		while parent.sheetCoordinator == nil { await Task.yield() }
		parent.sheetCoordinator?.dismiss()
		let result = await pending
		#expect(result == nil)
	}

	@Test func replacementResumesWithNil() async {
		// presenting something new over a pending presentation must not leave
		// the original caller suspended forever
		let parent = HarmonyCoordinator(TestScreen.home)
		async let pending: Int? = parent.present(.settings)
		while parent.sheetCoordinator == nil { await Task.yield() }
		parent.partialModal(.detail)
		let result = await pending
		#expect(result == nil)
		#expect(parent.sheetCoordinator?.root == .detail)
	}

	@Test func mismatchedResultTypeResumesWithNil() async {
		let parent = HarmonyCoordinator(TestScreen.home)
		async let pending: Int? = parent.present(.settings)
		while parent.sheetCoordinator == nil { await Task.yield() }
		parent.sheetCoordinator?.finish(returning: "not an int")
		let result = await pending
		#expect(result == nil)
	}

	@Test func swipeDismissalThroughBindingResumesWithNil() async {
		let parent = HarmonyCoordinator(TestScreen.home)
		async let pending: Int? = parent.present(.settings)
		while parent.sheetCoordinator == nil { await Task.yield() }
		parent.sheetCoordinator = nil
		let result = await pending
		#expect(result == nil)
	}

	@Test func dismissingParentResolvesNestedPresentation() async {
		// dismissing an outer presentation must resolve a presentation nested inside
		// it too, or the inner caller is suspended forever
		let parent = HarmonyCoordinator(TestScreen.home)
		async let outer: Int? = parent.present(.settings)
		while parent.sheetCoordinator == nil { await Task.yield() }
		let child = parent.sheetCoordinator!
		async let inner: Int? = child.present(.detail)
		while child.sheetCoordinator == nil { await Task.yield() }

		parent.sheetCoordinator = nil

		let outerResult = await outer
		let innerResult = await inner
		#expect(outerResult == nil)
		#expect(innerResult == nil)
	}

	@Test func collapseResolvesTabHostedBottomSheet() async {
		// collapsing a tab's stack must also drop (and resolve) a bottom sheet it
		// presented, which lives on the tab coordinator rather than the stack's slot
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let stack = tabs.coordinator(for: .home)
		async let pending: String? = stack.present(.detail, config: .init(action: .bottomSheet))
		while tabs.bottomSheetCoordinator == nil { await Task.yield() }
		stack.collapse()
		let result = await pending
		#expect(result == nil)
		#expect(tabs.bottomSheetCoordinator == nil)
	}

	@Test func tabHostedBottomSheetDeliversResult() async {
		// the result path works through the external host indirection too
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let stack = tabs.coordinator(for: .home)
		async let pending: String? = stack.present(.detail, config: .init(action: .bottomSheet))
		while tabs.bottomSheetCoordinator == nil { await Task.yield() }
		tabs.bottomSheetCoordinator?.finish(returning: "picked")
		let result = await pending
		#expect(result == "picked")
	}
}
