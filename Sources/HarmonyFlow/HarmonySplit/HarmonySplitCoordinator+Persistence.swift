//
//  HarmonySplitCoordinator+Persistence.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/12/26.
//

import Foundation

struct HarmonySplitSnapshot: Codable {
	var sidebar: HarmonySnapshot
	var content: [HarmonySnapshot]		// 0 or 1 elements; the optional middle column
	var detail: HarmonySnapshot
}

extension HarmonySplitCoordinator {
	var snapshot: HarmonySplitSnapshot {
		HarmonySplitSnapshot(
			sidebar: sidebarCoordinator.snapshot,
			content: contentCoordinator.map { [$0.snapshot] } ?? [],
			detail: detailCoordinator.snapshot
		)
	}

	public func encodedState() throws -> Data {
		try JSONEncoder().encode(snapshot)
	}

	public convenience init(restoring data: Data) throws {
		let snapshot = try JSONDecoder().decode(HarmonySplitSnapshot.self, from: data)
		self.init(
			sidebar: HarmonyCoordinator(snapshot: snapshot.sidebar),
			content: snapshot.content.first.map { HarmonyCoordinator(snapshot: $0) },
			detail: HarmonyCoordinator(snapshot: snapshot.detail)
		)
	}
}
