//
//  HarmonyCoordinator.ScreenAction.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import Foundation

extension HarmonyCoordinator {
	struct ScreenAction: Hashable {
		let screen: HarmonyScreen
		let action: HarmonyAction
	}
}
