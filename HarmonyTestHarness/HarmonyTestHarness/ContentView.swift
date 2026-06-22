//
//  ContentView.swift
//  HarmonyFlowTestHarness
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI
import HarmonyFlow

struct ContentView: View {
	@AppStorage("useSplitRoot") private var useSplitRoot = false
	@State private var tabs = HarmonyTabCoordinator(selected: AppTab.home)
	@State private var split = HarmonySplitCoordinator(sidebar: Screen.main, detail: Screen.settings)

	var body: some View {
		Group {
			if useSplitRoot {
				HarmonySplit(split)
			} else {
				HarmonyTabs(tabs)
			}
		}
		.safeAreaInset(edge: .bottom) {
			Toggle("Split View Root", isOn: $useSplitRoot)
				.padding(.horizontal)
				.padding(.vertical, 8)
				.background(.bar)
		}
	}
}

#Preview {
	ContentView()
}
