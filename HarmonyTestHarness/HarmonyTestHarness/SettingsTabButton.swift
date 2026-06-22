//
//  SettingsTabButton.swift
//  HarmonyFlowTestHarness
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI
import HarmonyFlow

struct SettingsTabButton: View {
	@Environment(HarmonyTabCoordinator<AppTab>.self) private var tabs: HarmonyTabCoordinator<AppTab>?

	var body: some View {
		if let tabs {
			Button("Titled Tab → main") {
				tabs.show(Screen.titled("Subtitled"), in: .settings)
			}
		}
	}
}
