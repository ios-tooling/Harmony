//
//  HarmonyFlowStack.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI


public struct HarmonyStack<Screen: HarmonyScreen>: View {
	// not @State: the coordinator is owned by its parent (app, tab, split, or
	// presenting coordinator), and container views may swap it out
	let coordinator: HarmonyCoordinator<Screen>

	public init(_ coordinator: HarmonyCoordinator<Screen>) {
		self.coordinator = coordinator
	}

	var config: HarmonyCoordinator<Screen>.ScreenConfiguration { .init(coordinator: coordinator) }

	public var body: some View {
		@Bindable var coordinator = coordinator

		NavigationStack(path: coordinator.pathBinding) {
			coordinator.root.body(configuration: config)
				.navigationDestination(for: Screen.self) { screen in
					screen.body(configuration: config)
				}
		}
		.environment(coordinator)
		.overlay(alignment: .bottom) {
			if let bottomSheet = coordinator.bottomSheetCoordinator {
				HarmonyBottomSheet(coordinator: bottomSheet)
					.id(bottomSheet.id)
					.transition(.identity)		// the sheet's layers transition individually: card slides, scrim fades
			}
		}
		.animation(.spring, value: coordinator.bottomSheetCoordinator?.id)
		#if os(iOS)
			.sheet(item: $coordinator.sheetCoordinator) { sheet in
				HarmonyStack(sheet)
					.presentationDetents(sheet.presentationDetents)
					.interactiveDismissDisabled(sheet.configuration.isInteractiveDismissDisabled)
			}
			.fullScreenCover(item: $coordinator.fullScreenCoordinator) { cover in
				HarmonyStack(cover)
			}
		#else
			.sheet(item: $coordinator.sheetCoordinator) { sheet in
				HarmonyStack(sheet)
					.interactiveDismissDisabled(sheet.configuration.isInteractiveDismissDisabled)
			}
		#endif
	}
}
