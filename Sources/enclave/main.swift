//
//  main.swift
//
//
//  Created by Alex Zenla on 3/31/22.
//
import ArgumentParser
import CryptoKit
import Foundation

if !SecureEnclave.isAvailable {
    fatalError("Secure Enclave is not available on this machine.")
}

EnclaveCommand.main()
