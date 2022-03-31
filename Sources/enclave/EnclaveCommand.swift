//
//  EnclaveCommand.swift
//
//
//  Created by Kenneth Endfinger on 3/31/22.
//

import ArgumentParser
import EnclaveKit
import Foundation

struct EnclaveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "enclave",
        abstract: "Secure Enclave Encryption Tool"
    )

    @Option(name: [
        .customShort("k"),
        .long
    ])
    var storedKeyFile: String = "\(FileManager.default.homeDirectoryForCurrentUser.path)/.enclave/key"

    @Flag(name: .shortAndLong)
    var decrypt: Bool = false

    @Flag(name: [
        .customShort("b"),
        .long
    ], inversion: .prefixedEnableDisable)
    var biometricDevice: Bool = true

    @Argument()
    var file: String

    func run() throws {
        let storedKeyURL = URL(fileURLWithPath: storedKeyFile)
        let key = try EnclavePrivateKey.loadOrCreate(at: storedKeyURL, requireBiometricDevice: biometricDevice)

        let fileURL = URL(fileURLWithPath: file)
        let data = try Data(contentsOf: fileURL)
        if decrypt {
            let decrypted = try key.decrypt(data)
            try FileHandle.standardOutput.write(contentsOf: decrypted)
        } else {
            let encrypted = try key.encrypt(data)
            try FileHandle.standardOutput.write(contentsOf: encrypted)
        }
    }
}
