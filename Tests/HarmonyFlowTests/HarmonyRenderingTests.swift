//
//  HarmonyFlowRenderingTests.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Testing
import SwiftUI
@testable import HarmonyFlow

// force-renders the same view trees Xcode previews do, so an environment or
// layout trap shows up here with a usable backtrace instead of a dead preview

#if canImport(UIKit)
import UIKit

@MainActor
struct HarmonyRenderingTests {
	private func render(_ root: some View) -> UIWindow {
		let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
		window.rootViewController = UIHostingController(rootView: root)
		window.makeKeyAndVisible()
		window.layoutIfNeeded()
		return window
	}

	@Test func stackTreeRendersWithoutTrapping() {
		let window = render(HarmonyStack(HarmonyCoordinator(TestScreen.home)))
		#expect(!(window.rootViewController?.view.subviews.isEmpty ?? true))
	}

	@Test func tabTreeRendersWithoutTrapping() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let window = render(HarmonyTabs(tabs))
		#expect(!(window.rootViewController?.view.subviews.isEmpty ?? true))
	}

	@Test func splitTreeRendersWithoutTrapping() {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, content: TestScreen.detail, detail: TestScreen.settings)
		let window = render(HarmonySplit(split))
		#expect(!(window.rootViewController?.view.subviews.isEmpty ?? true))
	}
}
#elseif canImport(AppKit)
import AppKit

@MainActor
struct HarmonyRenderingTests {
	@Test func stackTreeRendersWithoutTrapping() {
		let host = NSHostingView(rootView: HarmonyStack(HarmonyCoordinator(TestScreen.home)))
		host.setFrameSize(NSSize(width: 800, height: 600))
		host.layoutSubtreeIfNeeded()
		#expect(host.frame.width > 0)
	}

	@Test func tabTreeRendersWithoutTrapping() {
		let tabs = HarmonyTabCoordinator(selected: TestTab.home)
		let host = NSHostingView(rootView: HarmonyTabs(tabs))
		host.setFrameSize(NSSize(width: 800, height: 600))
		host.layoutSubtreeIfNeeded()
		#expect(host.frame.width > 0)
	}

	@Test func splitTreeRendersWithoutTrapping() {
		let split = HarmonySplitCoordinator(sidebar: TestScreen.home, content: TestScreen.detail, detail: TestScreen.settings)
		let host = NSHostingView(rootView: HarmonySplit(split))
		host.setFrameSize(NSSize(width: 800, height: 600))
		host.layoutSubtreeIfNeeded()
		#expect(host.frame.width > 0)
	}
}
#endif
