//
//  HarmonyFlowBottomSheet.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/10/26.
//

import SwiftUI

private enum SheetMetrics {
	static let cornerRadius: CGFloat = 40
	static let grabberWidth: CGFloat = 36
	static let grabberHeight: CGFloat = 5
	static let grabberPadding: CGFloat = 5
	static let topGap: CGFloat = 10
	static let maxDimOpacity = 0.2
	static let dismissThreshold = 0.6
}

struct HarmonyBottomSheet<Screen: HarmonyScreen>: View {
	let coordinator: HarmonyCoordinator<Screen>

	@State private var currentDetent: HarmonyDetent?
	@State private var dragAdjustment: CGFloat = 0

	private var detents: Set<HarmonyDetent> {
		guard let detents = coordinator.configuration.detents, !detents.isEmpty else { return [.fraction(1.0 / 3.0)] }
		return detents
	}

	var body: some View {
		GeometryReader { geo in
			let containerHeight = geo.size.height - geo.safeAreaInsets.top - SheetMetrics.topGap
			let heights = detents.map { $0.resolvedHeight(in: containerHeight) }.sorted()
			let resting = currentDetent?.resolvedHeight(in: containerHeight) ?? heights[0]
			let displayed = min(max(resting + dragAdjustment, 0), heights.last ?? resting)

			ZStack(alignment: .bottom) {
				Color.black
					.opacity(dimOpacity(displayed: displayed, smallest: heights[0], container: containerHeight))
					.contentShape(.rect)		// stays tappable even when the dim is fully transparent at the smallest detent
					.transition(.opacity)
					.onTapGesture { dismissOnScrimTap() }

				card(displayed: displayed, containerHeight: containerHeight, heights: heights, resting: resting)
					.transition(.move(edge: .bottom))
			}
		}
		.ignoresSafeArea()
	}

	private func dismissOnScrimTap() {
		guard !coordinator.configuration.isInteractiveDismissDisabled else { return }
		withAnimation(.spring) { coordinator.dismissStack() }
	}

	private func dimOpacity(displayed: CGFloat, smallest: CGFloat, container: CGFloat) -> Double {
		let range = max(container - smallest, 1)
		let progress = min(max((displayed - smallest) / range, 0), 1)
		return progress * SheetMetrics.maxDimOpacity
	}

	private func card(displayed: CGFloat, containerHeight: CGFloat, heights: [CGFloat], resting: CGFloat) -> some View {
		HarmonyStack(coordinator)
			.frame(height: displayed)
			.frame(maxWidth: .infinity)
			.background(.background)
			.clipShape(.rect(topLeadingRadius: SheetMetrics.cornerRadius, topTrailingRadius: SheetMetrics.cornerRadius))
			.overlay(alignment: .top) {
				grabber(containerHeight: containerHeight, heights: heights, resting: resting)
			}
			.shadow(color: .black.opacity(0.15), radius: 8, y: -4)
	}

	private func grabber(containerHeight: CGFloat, heights: [CGFloat], resting: CGFloat) -> some View {
		Capsule()
			.fill(.tertiary)
			.frame(width: SheetMetrics.grabberWidth, height: SheetMetrics.grabberHeight)
			.padding(.vertical, SheetMetrics.grabberPadding)
			.frame(maxWidth: .infinity)
			.contentShape(Rectangle())
			.gesture(dragGesture(containerHeight: containerHeight, heights: heights, resting: resting))
	}

	private func dragGesture(containerHeight: CGFloat, heights: [CGFloat], resting: CGFloat) -> some Gesture {
		DragGesture(coordinateSpace: .global)
			.onChanged { value in
				dragAdjustment = -value.translation.height
			}
			.onEnded { value in
				let projected = resting - value.predictedEndTranslation.height
				let canDismiss = !coordinator.configuration.isInteractiveDismissDisabled

				withAnimation(.spring) {
					dragAdjustment = 0
					if canDismiss, projected < (heights.first ?? 0) * SheetMetrics.dismissThreshold {
						coordinator.dismissStack()
					} else {
						currentDetent = detents.min { abs($0.resolvedHeight(in: containerHeight) - projected) < abs($1.resolvedHeight(in: containerHeight) - projected) }
					}
				}
			}
	}
}
