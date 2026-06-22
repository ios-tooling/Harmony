//
//  ProfileScreen.swift
//  HarmonyFlowTestHarness
//
//  Created by Ben Gottlieb on 6/21/26.
//

import SwiftUI
import HarmonyFlow

// a second, independent destination type — as if it lived in its own framework.
// It shares nothing with `Screen`, yet both coexist in the same HarmonyStack: a
// `Screen` can push a `ProfileScreen` and vice-versa, with no central enum.
enum ProfileScreen: HarmonyDestination {
	case profile, editor

	var id: String { String(describing: self) }

	func body(configuration: HarmonyScreenConfiguration) -> some View {
		VStack {
			Text("profile: \(id)")

			Button("Push Editor") {
				configuration.coordinator.push(ProfileScreen.editor)
			}

			Button("Cross to Settings (other type)") {
				configuration.coordinator.push(Screen.settings)
			}

			Button("Dismiss") {
				configuration.coordinator.dismiss()
			}
		}
		.navigationTitle("Profile")
	}
}
