//
//  HarmonyScreen.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI

// the single concrete type the whole coordinator tree is built on: a type-erased
// box around any framework's HarmonyDestination. AnyHashable supplies cross-module
// identity (two destinations of different types are never equal)
public struct HarmonyScreen: Identifiable, Hashable {
	let destination: any HarmonyDestination

	public init(_ destination: any HarmonyDestination) { self.destination = destination }

	public var id: AnyHashable { AnyHashable(destination) }

	public static func == (lhs: HarmonyScreen, rhs: HarmonyScreen) -> Bool { lhs.id == rhs.id }
	public func hash(into hasher: inout Hasher) { hasher.combine(id) }

	@MainActor func body(configuration: HarmonyScreenConfiguration) -> AnyView {
		erasedBody(destination, configuration)
	}
}

// opens the existential to its concrete type so the destination renders with its
// real body; the AnyView lands only at this screen's root, nowhere inside it
@MainActor private func erasedBody<D: HarmonyDestination>(_ destination: D, _ configuration: HarmonyScreenConfiguration) -> AnyView {
	AnyView(destination.body(configuration: configuration))
}
