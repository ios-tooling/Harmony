//
//  HarmonyCoordinator+Path.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/10/26.
//

import SwiftUI

extension HarmonyCoordinator {
	var fullPath: [HarmonyScreen] {
		_screens.map(\.screen)
	}

	var pathBinding: Binding<[HarmonyScreen]> {
		Binding(get: {
			self.fullPath
		}, set: { newPath in
			self._screens = newPath.map { ScreenAction(screen: $0, action: .push) }
		})
	}
}
