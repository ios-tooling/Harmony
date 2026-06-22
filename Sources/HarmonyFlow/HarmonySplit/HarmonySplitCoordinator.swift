//
//  HarmonySplitCoordinator.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

@MainActor @Observable public class HarmonySplitCoordinator {
	public var columnVisibility: NavigationSplitViewVisibility = .automatic
	public internal(set) var sidebarCoordinator: HarmonyCoordinator
	public internal(set) var contentCoordinator: HarmonyCoordinator?
	public internal(set) var detailCoordinator: HarmonyCoordinator

	public init(sidebar: any HarmonyDestination, content: (any HarmonyDestination)? = nil, detail: any HarmonyDestination) {
		sidebarCoordinator = HarmonyCoordinator(sidebar)
		contentCoordinator = content.map { HarmonyCoordinator($0) }
		detailCoordinator = HarmonyCoordinator(detail)
	}

	init(sidebar: HarmonyCoordinator, content: HarmonyCoordinator?, detail: HarmonyCoordinator) {
		sidebarCoordinator = sidebar
		contentCoordinator = content
		detailCoordinator = detail
	}

	// selection-style navigation: replaces the column's stack entirely
	public func showDetail(_ destination: any HarmonyDestination) {
		detailCoordinator = HarmonyCoordinator(destination)
	}

	public func showContent(_ destination: any HarmonyDestination) {
		contentCoordinator = HarmonyCoordinator(destination)
	}
}
