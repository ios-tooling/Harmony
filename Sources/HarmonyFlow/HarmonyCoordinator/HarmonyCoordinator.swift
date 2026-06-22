//
//  HarmonyCoordinator.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI

@MainActor @Observable public class HarmonyCoordinator: Identifiable, HarmonyBottomSheetHosting {
	var _screens: [ScreenAction] = []

	var parentCoordinator: HarmonyCoordinator?
	var modalCoordinator: HarmonyCoordinator? {
		didSet { if oldValue !== modalCoordinator { oldValue?.tearDownPresentation() } }
	}
	var bottomSheetCoordinator: HarmonyCoordinator? {
		didSet { if oldValue !== bottomSheetCoordinator { oldValue?.tearDownPresentation() } }
	}

	// presentation-result plumbing: the slot didSets above guarantee exactly-once
	// resolution however the presentation ends
	@ObservationIgnored var pendingPresentationContinuation: CheckedContinuation<(any Sendable)?, Never>?
	@ObservationIgnored var pendingPresentationResult: (any Sendable)?

	// when set (e.g. by a tab coordinator), bottom sheets presented here are hosted
	// there instead, so they can render above container chrome like the tab bar
	@ObservationIgnored weak var externalBottomSheetHost: (any HarmonyBottomSheetHosting)?
	var root: HarmonyScreen
	var configuration = HarmonyNavigationConfiguration(action: .push)

	var action: HarmonyAction { configuration.action }

	nonisolated public var id: ObjectIdentifier { ObjectIdentifier(self) }

	public init(_ screen: HarmonyScreen) {
		root = screen
	}

	public convenience init(_ destination: any HarmonyDestination) {
		self.init(HarmonyScreen(destination))
	}

	public init(_ path: [HarmonyScreen]) {
		precondition(!path.isEmpty, "HarmonyCoordinator requires at least one screen")
		root = path[0]
		_screens = path.dropFirst().map { ScreenAction(screen: $0, action: .push) }
	}

	public convenience init(_ path: [any HarmonyDestination]) {
		self.init(path.map { HarmonyScreen($0) })
	}

	func removeFromParentCoordinator() {
		if let externalBottomSheetHost {
			if externalBottomSheetHost.bottomSheetCoordinator === self { externalBottomSheetHost.bottomSheetCoordinator = nil }
			return
		}

		guard let parentCoordinator else { return }

		if parentCoordinator.modalCoordinator === self { parentCoordinator.modalCoordinator = nil }
		if parentCoordinator.bottomSheetCoordinator === self { parentCoordinator.bottomSheetCoordinator = nil }
	}

	// the nearest enclosing context that can host a bottom sheet: bottom sheets
	// never stack on bottom sheets, so those defer to their parent
	var bottomSheetHost: HarmonyCoordinator {
		action == .bottomSheet ? (parentCoordinator?.bottomSheetHost ?? self) : self
	}

	@discardableResult func addChild(_ screen: HarmonyScreen, configuration: HarmonyNavigationConfiguration) -> HarmonyCoordinator {
		let new = HarmonyCoordinator([screen])
		new.configuration = configuration

		if configuration.action == .bottomSheet {
			let host = bottomSheetHost
			new.parentCoordinator = host

			if let external = host.externalBottomSheetHost {
				new.externalBottomSheetHost = external
				external.bottomSheetCoordinator = new
			} else {
				host.bottomSheetCoordinator = new
			}
		} else {
			new.parentCoordinator = self
			modalCoordinator = new
		}
		return new
	}

	func resolvePendingPresentation() {
		pendingPresentationContinuation?.resume(returning: pendingPresentationResult)
		pendingPresentationContinuation = nil
		pendingPresentationResult = nil
	}

	// recursively resolves this coordinator's pending continuation and tears down
	// anything it presented, so dismissing a presentation never orphans a nested
	// present-for-result continuation deeper in the subtree (the nil assignments
	// re-enter this method through the slot didSets; identity-guarded, so a nil
	// slot is a no-op and recursion terminates at the leaves)
	func tearDownPresentation() {
		resolvePendingPresentation()
		modalCoordinator = nil
		bottomSheetCoordinator = nil
	}

	var sheetCoordinator: HarmonyCoordinator? {
		get {
			guard let modalCoordinator, modalCoordinator.action.isSheet else { return nil }
			return modalCoordinator
		}
		set {
			if newValue == nil, modalCoordinator?.action.isSheet == true { modalCoordinator = nil }
		}
	}

	var fullScreenCoordinator: HarmonyCoordinator? {
		get {
			#if os(macOS)
				return nil
			#else
				guard let modalCoordinator, modalCoordinator.action == .fullScreenModal else { return nil }
				return modalCoordinator
			#endif
		}
		set {
			if newValue == nil, modalCoordinator?.action == .fullScreenModal { modalCoordinator = nil }
		}
	}
}
