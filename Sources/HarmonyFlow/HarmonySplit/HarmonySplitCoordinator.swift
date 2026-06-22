//
//  HarmonyFlowSplitCoordinator.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

@MainActor @Observable public class HarmonySplitCoordinator<Screen: HarmonyScreen> {
	public var columnVisibility: NavigationSplitViewVisibility = .automatic
	public internal(set) var sidebarCoordinator: HarmonyCoordinator<Screen>
	public internal(set) var contentCoordinator: HarmonyCoordinator<Screen>?
	public internal(set) var detailCoordinator: HarmonyCoordinator<Screen>

	public init(sidebar: Screen, content: Screen? = nil, detail: Screen) {
		sidebarCoordinator = HarmonyCoordinator(sidebar)
		contentCoordinator = content.map { HarmonyCoordinator($0) }
		detailCoordinator = HarmonyCoordinator(detail)
	}

	init(sidebar: HarmonyCoordinator<Screen>, content: HarmonyCoordinator<Screen>?, detail: HarmonyCoordinator<Screen>) {
		sidebarCoordinator = sidebar
		contentCoordinator = content
		detailCoordinator = detail
	}

	// selection-style navigation: replaces the column's stack entirely
	public func showDetail(_ screen: Screen) {
		detailCoordinator = HarmonyCoordinator(screen)
	}

	public func showContent(_ screen: Screen) {
		contentCoordinator = HarmonyCoordinator(screen)
	}
}
