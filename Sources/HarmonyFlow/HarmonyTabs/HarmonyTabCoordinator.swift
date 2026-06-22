//
//  HarmonyFlowTabCoordinator.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

@MainActor @Observable public class HarmonyTabCoordinator<Tab: HarmonyTab>: HarmonyBottomSheetHosting {
	public var selectedTab: Tab
	public var isTabBarHidden = false
	var bottomSheetCoordinator: HarmonyCoordinator<Tab.Screen>? {
		didSet { if oldValue !== bottomSheetCoordinator { oldValue?.tearDownPresentation() } }
	}
	var stacks: [Tab: HarmonyCoordinator<Tab.Screen>] = [:]

	public init(selected: Tab) {
		selectedTab = selected
		for tab in Tab.allCases {
			let stack = HarmonyCoordinator(tab.rootScreen)
			stack.externalBottomSheetHost = self
			stacks[tab] = stack
		}
	}

	public func coordinator(for tab: Tab) -> HarmonyCoordinator<Tab.Screen> {
		guard let stack = stacks[tab] else {
			preconditionFailure("HarmonyTabCoordinator has no stack for \(tab)")
		}
		return stack
	}

	public func show(_ screen: Tab.Screen, in tab: Tab, config: HarmonyNavigationConfiguration = .init(action: .push)) {
		selectedTab = tab
		coordinator(for: tab).show(screen, config: config)
	}

	public func collapse(_ tab: Tab? = nil) {
		coordinator(for: tab ?? selectedTab).collapse()
	}
}
