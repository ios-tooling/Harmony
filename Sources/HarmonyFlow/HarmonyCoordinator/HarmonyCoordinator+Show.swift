//
//  HarmonyFlowCoordinator+Show.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import Foundation

extension HarmonyCoordinator {
	public func show(_ screen: Screen, config: HarmonyNavigationConfiguration) {
		let action = config.action
		
		switch action {
		case .push:
			_screens.append(.init(screen: screen, action: action))

		case .bottomSheet, .partialModal, .fullScreenModal:
			addChild(screen, configuration: config)
		}
	}
	
	public func push(_ screen: Screen) { show(screen, config: .init(action: .push)) }
	public func bottomSheet(_ screen: Screen) { show(screen, config: .init(action: .bottomSheet)) }
	public func partialModal(_ screen: Screen) { show(screen, config: .init(action: .partialModal)) }
	public func fullScreenModal(_ screen: Screen) { show(screen, config: .init(action: .fullScreenModal)) }

	public func dismiss() {
		if _screens.isEmpty {
			removeFromParentCoordinator()
		} else {
			_screens.removeLast()
		}
	}

	public func dismissStack() {
		removeFromParentCoordinator()
	}

	public func popToRoot() {
		_screens.removeAll()
	}

	// deep-link entry point: swaps the entire pushed path in one step
	public func replacePath(_ path: [Screen]) {
		_screens = path.map { ScreenAction(screen: $0, action: .push) }
	}

	// pops back to the most recent occurrence of the screen; popping to the root
	// screen clears the path, and a screen not in the stack is a no-op
	public func pop(to screen: Screen) {
		if let index = _screens.lastIndex(where: { $0.screen == screen }) {
			_screens.removeSubrange(_screens.index(after: index)...)
		} else if screen == root {
			popToRoot()
		}
	}

	// returns the stack to its pristine root: pops all pushes and drops anything it presented
	public func collapse() {
		_screens.removeAll()
		modalCoordinator = nil
		bottomSheetCoordinator = nil
		// a bottom sheet presented from this stack under tabs lives on the external
		// host, not in our own slot, so clear it there if it belongs to us
		if let externalBottomSheetHost, externalBottomSheetHost.bottomSheetCoordinator?.parentCoordinator === self {
			externalBottomSheetHost.bottomSheetCoordinator = nil
		}
	}
}
