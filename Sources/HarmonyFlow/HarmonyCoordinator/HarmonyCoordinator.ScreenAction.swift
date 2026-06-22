//
//  HarmonyCoordinator.ScreenAction.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import Foundation

extension HarmonyCoordinator {
	struct ScreenAction: Hashable, Equatable {
        let screen: Screen
        let action: HarmonyAction
		
		static func == (lhs: ScreenAction, rhs: ScreenAction) -> Bool {
			lhs.screen == rhs.screen && lhs.action == rhs.action
		}
		
		func hash(into hasher: inout Hasher) {
			screen.hash(into: &hasher)
			action.hash(into: &hasher)
		}
    }
}
