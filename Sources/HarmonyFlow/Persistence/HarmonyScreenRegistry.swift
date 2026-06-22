//
//  HarmonyScreenRegistry.swift
//  HarmonyFlow
//
//  Created by Ben Gottlieb on 6/13/26.
//

import Foundation

// polymorphic-Codable support: because the coordinator tree stores erased
// `any HarmonyDestination` values, persistence needs a way to recover the
// concrete type on decode. Each framework registers its Codable destinations
// under a stable string key (typically at launch). Unregistered types simply
// fail to encode/decode, which the restore paths treat as "skip".
//
// Storage is `nonisolated(unsafe)` and serialized by the lock, so the registry
// is reachable from the nonisolated Codable methods on HarmonyScreen.
public enum HarmonyScreenRegistry {
	typealias Encode = (any HarmonyDestination, any Encoder) throws -> Void
	typealias Decode = (any Decoder) throws -> any HarmonyDestination

	private static let lock = NSLock()
	nonisolated(unsafe) private static var keysByType: [ObjectIdentifier: String] = [:]
	nonisolated(unsafe) private static var encodersByType: [ObjectIdentifier: Encode] = [:]
	nonisolated(unsafe) private static var decodersByKey: [String: Decode] = [:]

	public static func register<D: HarmonyDestination & Codable>(_ type: D.Type, forKey key: String) {
		lock.lock()
		defer { lock.unlock() }
		let id = ObjectIdentifier(type)
		keysByType[id] = key
		encodersByType[id] = { destination, encoder in try (destination as! D).encode(to: encoder) }
		decodersByKey[key] = { decoder in try D(from: decoder) }
	}

	static func registration(for type: any HarmonyDestination.Type) -> (key: String, encode: Encode)? {
		lock.lock()
		defer { lock.unlock() }
		let id = ObjectIdentifier(type)
		guard let key = keysByType[id], let encode = encodersByType[id] else { return nil }
		return (key, encode)
	}

	static func decoder(forKey key: String) -> Decode? {
		lock.lock()
		defer { lock.unlock() }
		return decodersByKey[key]
	}
}
