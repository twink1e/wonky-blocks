//
//  GamePhysicsController.swift
//  Wonky Blocks
//
//  Created by Benjamin Kindle on 6/14/20.
//  Copyright © 2020 Benjamin Kindle. All rights reserved.
//

import SpriteKit
import Combine
//import SwiftClipper

class GamePhysicsController: NSObject, SKPhysicsContactDelegate {
    var can: Cancellable?
    var leftPressed = false
    var leftTouchPressed = false
    var rightPressed = false
    var rightTouchPressed = false
    var upPressed = false
    var downPressed = false
    var rotateLeftPressed = false
    var rotateRightPressed = false
    /// if the keyboard is ever used, joystick movement will be disabled
    var keyboardUsed = false

    override init() {
        super.init()
        can = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().sink(receiveValue: { (_) in
            self.handleKeyEvents()
        })
    }

    var activePiece: WonkyTetronimo?
    var activePieceContact = PassthroughSubject<Void, Never>()

    func didBegin(_ contact: SKPhysicsContact) {
        guard activePiece != nil else {return}
        guard contact.bodyB.node?.name != "row",
            contact.bodyA.node?.name != "row" else {return}
        // only bodyB is ever activeTet
        let activeTetContact = contact.bodyB.node?.name == "activeTet" ||
            contact.bodyA.node?.name == "activeTet"
        let groundContact = contact.bodyA.node?.name == "ground" ||
            contact.bodyB.node?.name == "ground"
        let otherTetContact = contact.bodyA.node?.name == "tet" ||
            contact.bodyB.node?.name == "tet"
        if activeTetContact && (groundContact || otherTetContact) {
            activePieceContact.send()
        }
    }

    deinit {
        can?.cancel()
    }
}
