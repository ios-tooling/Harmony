//
//  ShowDetailButton.swift
//  HarmonyFlowTestHarness
//
//  Created by Ben Gottlieb on 6/11/26.
//

import SwiftUI
import HarmonyFlow

struct ShowDetailButton: View {
	@Environment(HarmonySplitCoordinator.self) private var split: HarmonySplitCoordinator?
	@State private var count = 0

	var body: some View {
		if let split {
			Button("Show Detail #\(count + 1)") {
				count += 1
				split.showDetail(Screen.titled("Detail #\(count)"))
			}
		}
	}
}
