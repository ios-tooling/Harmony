//
//  HarmonyDestination.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/9/26.
//

import SwiftUI

// each framework conforms its own enum/struct to this — no shared screen type,
// no central enum. Values are boxed into a HarmonyScreen for the coordinator tree.
public protocol HarmonyDestination: Hashable {
	associatedtype Body: View

	@MainActor @ViewBuilder func body(configuration: HarmonyScreenConfiguration) -> Body
}
