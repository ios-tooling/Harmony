//
//  HarmonyFlowCoordinator+Present.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/11/26.
//

import Foundation

extension HarmonyCoordinator {
	// presents the screen and suspends until it finishes or is dismissed; any
	// dismissal path that doesn't supply a value (swipe, dismiss(), replacement)
	// resumes with nil, as does a value that doesn't match the expected type
	public func present<Result: Sendable>(_ destination: any HarmonyDestination, config: HarmonyNavigationConfiguration = .init(action: .partialModal)) async -> Result? {
		precondition(config.action != .push, "present(_:config:) requires a modal or bottom sheet action; use push(_:) for stack navigation")

		let child = addChild(HarmonyScreen(destination), configuration: config)
		let result = await withCheckedContinuation { continuation in
			child.pendingPresentationContinuation = continuation
		}
		return result as? Result
	}

	// supplies the result for this presented flow and dismisses it
	public func finish(returning result: (any Sendable)?) {
		pendingPresentationResult = result
		removeFromParentCoordinator()
	}
}
