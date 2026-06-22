//
//  HarmonyScreen+Codable.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/13/26.
//

import Foundation

// encodes as { type: <registered key>, value: <destination payload> }, looking the
// concrete type up in HarmonyScreenRegistry on the way in and out
extension HarmonyScreen: Codable {
	private enum CodingKeys: String, CodingKey { case type, value }

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let key = try container.decode(String.self, forKey: .type)
		guard let make = HarmonyScreenRegistry.decoder(forKey: key) else {
			throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "No HarmonyDestination registered for key \"\(key)\"")
		}
		destination = try make(container.superDecoder(forKey: .value))
	}

	public func encode(to encoder: any Encoder) throws {
		guard let registration = HarmonyScreenRegistry.registration(for: type(of: destination)) else {
			throw EncodingError.invalidValue(destination, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "HarmonyDestination type \(type(of: destination)) is not registered — call HarmonyScreenRegistry.register(_:forKey:)"))
		}
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(registration.key, forKey: .type)
		try registration.encode(destination, container.superEncoder(forKey: .value))
	}
}
