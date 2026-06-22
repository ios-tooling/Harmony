//
//  HarmonyBottomSheetHosting.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Foundation

@MainActor protocol HarmonyBottomSheetHosting: AnyObject {
	var bottomSheetCoordinator: HarmonyCoordinator? { get set }
}
