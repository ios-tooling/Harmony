//
//  HarmonyTabCoordinator.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

@MainActor @Observable public class HarmonyTabCoordinator<Tab: HarmonyTab>: HarmonyBottomSheetHosting {
	public var selectedTab: Tab
	public var isTabBarHidden = false
	var bottomSheetCoordinator: HarmonyCoordinator? {
		didSet { if oldValue !== bottomSheetCoordinator { oldValue?.tearDownPresentation() } }
	}
	var stacks: [Tab: HarmonyCoordinator] = [:]

	public init(selected: Tab) {
		selectedTab = selected
		for tab in Tab.allCases {
			let stack = HarmonyCoordinator(tab.rootScreen)
			stack.externalBottomSheetHost = self
			stacks[tab] = stack
		}
	}

	public func coordinator(for tab: Tab) -> HarmonyCoordinator {
		guard let stack = stacks[tab] else {
			preconditionFailure("HarmonyTabCoordinator has no stack for \(tab)")
		}
		return stack
	}

	public func show(_ destination: any HarmonyDestination, in tab: Tab, config: HarmonyNavigationConfiguration = .init(action: .push)) {
		selectedTab = tab
		coordinator(for: tab).show(destination, config: config)
	}

	public func collapse(_ tab: Tab? = nil) {
		coordinator(for: tab ?? selectedTab).collapse()
	}
}
