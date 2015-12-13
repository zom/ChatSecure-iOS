//
//  SodiumTests.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 12/12/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import XCTest
import ChatSecureCore

class SodiumTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testEd25519KeyPairGeneration() {
        let keyPair = Sodium.generateKeyPair(KeyPairType.Ed25519)
        NSLog("keyPair: %@", keyPair.publicKey)
    }
    
}
