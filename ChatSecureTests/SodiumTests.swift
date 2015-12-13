//
//  SodiumTests.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 12/13/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import XCTest
import Sodium
import Base32

class SodiumTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEd25519Username() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let sodium = Sodium()!
        let keyPair = sodium.sign.keyPair()!
        let pk = keyPair.publicKey
        let b32pk = pk.base32String().lowercaseString
        let stripped = b32pk.stringByReplacingOccurrencesOfString("=", withString: "")
        let pk2 = NSData(base32String: stripped)
        XCTAssertEqual(pk, pk2)
        NSLog("stripped: %@", stripped)
        NSLog("pk1 %@", pk)
        NSLog("pk2 %@", pk2)
    }
}
