//
//  HarmonyTabCoordinator+Persistence.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/12/26.
//

import Foundation

struct HarmonyTabSnapshot<Tab: HarmonyTab & Codable>: Codable {
	var selectedTab: Tab
	var isTabBarHidden: Bool
	var stacks: [Tab: HarmonySnapshot]
	var bottomSheet: [HarmonySnapshot]		// 0 or 1 elements; the tab-level sheet
}

extension HarmonyTabCoordinator where Tab: Codable {
	var snapshot: HarmonyTabSnapshot<Tab> {
		HarmonyTabSnapshot(
			selectedTab: selectedTab,
			isTabBarHidden: isTabBarHidden,
			stacks: stacks.mapValues { $0.snapshot },
			bottomSheet: bottomSheetCoordinator.map { [$0.snapshot] } ?? []
		)
	}

	public func encodedState() throws -> Data {
		try JSONEncoder().encode(snapshot)
	}

	public convenience init(restoring data: Data) throws {
		let snapshot = try JSONDecoder().decode(HarmonyTabSnapshot<Tab>.self, from: data)
		self.init(selected: snapshot.selectedTab)
		isTabBarHidden = snapshot.isTabBarHidden

		// tabs missing from the snapshot (e.g. added in an app update) keep the
		// fresh stacks the designated init created
		for (tab, stackSnapshot) in snapshot.stacks {
			let stack = HarmonyCoordinator(snapshot: stackSnapshot)
			stack.externalBottomSheetHost = self
			stacks[tab] = stack
		}

		if let sheetSnapshot = snapshot.bottomSheet.first {
			let sheet = HarmonyCoordinator(snapshot: sheetSnapshot)
			sheet.externalBottomSheetHost = self
			sheet.parentCoordinator = stacks[snapshot.selectedTab]
			bottomSheetCoordinator = sheet
		}
	}
}
