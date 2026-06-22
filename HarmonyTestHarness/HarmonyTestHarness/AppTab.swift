//
//  AppTab.swift
//  HarmonyFlowTestHarness
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI
import HarmonyFlow

enum AppTab: String, HarmonyTab {
	case home, settings

	var rootScreen: any HarmonyDestination {
		switch self {
		case .home: Screen.main
		case .settings: Screen.settings
		}
	}

	var label: some View {
		switch self {
		case .home: Label("Home", systemImage: "house")
		case .settings: Label("Settings", systemImage: "gear")
		}
	}
}
