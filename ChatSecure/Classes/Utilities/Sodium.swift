//
//  Sodium.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 12/12/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import libsodium

public enum KeyPairType {
    case Undefined
    case Curve25519
    case Ed25519
}

public class KeyPair: NSObject {
    public let type: KeyPairType
    public let publicKey: NSData
    public let privateKey: NSData
    
    public init(type: KeyPairType, publicKey: NSData, privateKey: NSData) {
        self.type = type
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
}

public class Sodium: NSObject {
    override public class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            sodium_init()
        }
    }
    
    public class func generateKeyPair(type: KeyPairType) -> KeyPair {
        var publicKey = NSData()
        var privateKey = NSData()
        switch type {
        case .Curve25519:
            break
        case .Ed25519:
            let publicKeySize = crypto_sign_ed25519_publickeybytes()
            let privateKeySize = crypto_sign_ed25519_secretkeybytes()
            let pk = UnsafeMutablePointer<UInt8>.alloc(publicKeySize)
            let sk = UnsafeMutablePointer<UInt8>.alloc(privateKeySize)
            crypto_sign_keypair(pk, sk)
            publicKey = NSData(bytesNoCopy: pk, length: publicKeySize, freeWhenDone: true)
            privateKey = NSData(bytesNoCopy: sk, length: privateKeySize, freeWhenDone: true)
            break
        default:
            break
        }
        return KeyPair(type: type, publicKey: publicKey, privateKey: privateKey)
    }
}
