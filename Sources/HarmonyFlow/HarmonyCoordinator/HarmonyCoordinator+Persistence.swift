//
//  HarmonyCoordinator+Persistence.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/12/26.
//

import Foundation

// whole-tree state persistence. HarmonyScreen is always Codable (via the registry),
// so this is unconditional now — but a screen whose destination type wasn't
// registered will throw on encode/decode.
struct HarmonySnapshot: Codable {
	var root: HarmonyScreen
	var path: [HarmonyScreen]
	var configuration: HarmonyNavigationConfiguration
	var modal: [HarmonySnapshot]		// 0 or 1 elements; an array only to break struct recursion
	var bottomSheet: [HarmonySnapshot]
}

extension HarmonyCoordinator {
	var snapshot: HarmonySnapshot {
		HarmonySnapshot(
			root: root,
			path: fullPath,
			configuration: configuration,
			modal: modalCoordinator.map { [$0.snapshot] } ?? [],
			bottomSheet: bottomSheetCoordinator.map { [$0.snapshot] } ?? []
		)
	}

	public func encodedState() throws -> Data {
		try JSONEncoder().encode(snapshot)
	}

	public convenience init(restoring data: Data) throws {
		let snapshot = try JSONDecoder().decode(HarmonySnapshot.self, from: data)
		self.init(snapshot: snapshot)
	}

	convenience init(snapshot: HarmonySnapshot) {
		self.init([snapshot.root] + snapshot.path)
		configuration = snapshot.configuration

		if let modal = snapshot.modal.first {
			let child = HarmonyCoordinator(snapshot: modal)
			child.parentCoordinator = self
			modalCoordinator = child
		}

		if let sheet = snapshot.bottomSheet.first {
			let child = HarmonyCoordinator(snapshot: sheet)
			child.parentCoordinator = self
			bottomSheetCoordinator = child
		}
	}
}
