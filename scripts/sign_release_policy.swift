#!/usr/bin/swift
import Foundation
import CryptoKit

// Owner-run signing utility. Key file: base64 raw 32-byte Ed25519 private key,
// outside the checkout. This tool neither generates nor prints a private key.
guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: swift scripts/sign_release_policy.swift /private/key-file /path/payload.json")
}
let keyText = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
guard let keyData = Data(base64Encoded: keyText), keyData.count == 32 else { fatalError("Expected raw base64 Ed25519 private key") }
let key = try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
let payload = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))
_ = try JSONSerialization.jsonObject(with: payload)
let envelope = ["payload": payload.base64EncodedString(), "signature": try key.signature(for: payload).base64EncodedString()]
let result = try JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys])
print(String(decoding: result, as: UTF8.self))
