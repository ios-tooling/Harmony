//
//  PresentResultButton.swift
//  HarmonyFlowTestHarness
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI
import HarmonyFlow

struct PresentResultButton: View {
	@Environment(HarmonyCoordinator.self) private var coordinator
	@State private var lastResult = "none yet"

	var body: some View {
		Button("Present for Result (got: \(lastResult))") {
			Task {
				let value: String? = await coordinator.present(Screen.settings)
				lastResult = value ?? "cancelled"
			}
		}
	}
}
