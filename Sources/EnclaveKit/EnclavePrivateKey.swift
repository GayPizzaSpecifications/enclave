//
//  EnclavePrivateKey.swift
//
//
//  Created by Alex Endfinger on 3/31/22.
//
import CryptoKit
import Foundation
import LocalAuthentication

public struct EnclavePrivateKey {
    public let privateKey: SecureEnclave.P256.KeyAgreement.PrivateKey
    public let salt: Data

    public init(authenticationContext: LAContext = LAContext(), requireBiometricDevice: Bool = true) throws {
        var attributes: [SecAccessControlCreateFlags] = [
            .privateKeyUsage
        ]

        if requireBiometricDevice {
            attributes.append(.biometryCurrentSet)
        }

        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            SecAccessControlCreateFlags(attributes), nil
        )!

        privateKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(
            accessControl: access, authenticationContext: authenticationContext
        )
        salt = EnclavePrivateKey.randomData(length: 64)
    }

    public init(key: SecureEnclave.P256.KeyAgreement.PrivateKey, salt: Data) {
        privateKey = key
        self.salt = salt
    }

    public init(dataRepresentation data: Data, authenticationContext: LAContext = LAContext()) throws {
        guard let content = String(data: data, encoding: .utf8) else {
            throw EnclaveError.badDataRepresentation
        }
        let parts = content.split(separator: ".")
        if parts.count != 2 {
            throw EnclaveError.badDataRepresentation
        }

        let keyBase64String = String(parts[0])
        let saltBase64String = String(parts[1])

        guard let keyData = Data(base64Encoded: keyBase64String) else {
            throw EnclaveError.badDataRepresentation
        }

        guard let saltData = Data(base64Encoded: saltBase64String) else {
            throw EnclaveError.badDataRepresentation
        }

        privateKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(
            dataRepresentation: keyData, authenticationContext: authenticationContext
        )
        salt = saltData
    }

    public static func loadOrCreate(at url: URL,
                                    authenticationContext: LAContext = LAContext(),
                                    requireBiometricDevice: Bool = true) throws -> EnclavePrivateKey
    {
        let key: EnclavePrivateKey
        if !FileManager.default.fileExists(atPath: url.path) {
            key = try EnclavePrivateKey(
                authenticationContext: authenticationContext, requireBiometricDevice: requireBiometricDevice
            )
            let data = key.dataRepresentation
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try data.write(to: url)
        } else {
            let data = try Data(contentsOf: url)
            key = try EnclavePrivateKey(dataRepresentation: data)
        }
        return key
    }

    public var dataRepresentation: Data {
        let keyEncoded = privateKey.dataRepresentation.base64EncodedString()
        let saltEncoded = salt.base64EncodedString()
        guard let encoded = "\(keyEncoded).\(saltEncoded)".data(using: .utf8) else {
            fatalError("Failed to encode secure enclave key to data.")
        }
        return encoded
    }

    public func encrypt(_ data: Data) throws -> Data {
        let key = try getSymmetricKey()
        return try ChaChaPoly.seal(data, using: key).combined
    }

    public func decrypt(_ data: Data) throws -> Data {
        let key = try getSymmetricKey()
        let box = try ChaChaPoly.SealedBox(combined: data)
        return try ChaChaPoly.open(box, using: key)
    }

    public func getSymmetricKey() throws -> SymmetricKey {
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: privateKey.publicKey)
        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: salt,
            sharedInfo: privateKey.publicKey.rawRepresentation,
            outputByteCount: 32
        )
    }

    private static func randomData(length: Int) -> Data {
        var data = Data(count: length)
        _ = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        return data
    }
}
