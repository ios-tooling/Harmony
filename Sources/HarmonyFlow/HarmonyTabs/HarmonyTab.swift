//
//  HarmonyTab.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI

public protocol HarmonyTab: Hashable, CaseIterable {
	associatedtype TabLabel: View

	var rootScreen: any HarmonyDestination { get }
	@MainActor @ViewBuilder var label: TabLabel { get }
}
