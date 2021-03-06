//
//  Tetronimo.swift
//  Wonky Blocks
//
//  Created by Benjamin Kindle on 6/14/20.
//  Copyright © 2020 Benjamin Kindle. All rights reserved.
//

import SpriteKit
import SwiftClipper

class WonkyTetronimo: SKShapeNode {
    var center: CGPoint {
        let originX = children.map {(($0 as? SKShapeNode)?.path?.boundingBox.origin.x)!}
        let originY = children.map {(($0 as? SKShapeNode)?.path?.boundingBox.origin.y)!}
        let midX = (originX.max()! + originX.min()!) / 2
        let midY = (originY.max()! + originY.min()!) / 2
        let center = CGPoint(x: midX + 25, y: midY + 25)
        return center
    }

    /// initialize using a grid of rows and columns indicating whether each position should include a block or be empty
    init(grid: [[Bool]], color: UIColor = currentTheme.randomColor) {
        super.init()
        var physicsBodies: [SKPhysicsBody] = []
        for col in grid.enumerated() {
            for row in col.element.enumerated() {
                if row.element {
                    // width and height are not 50 because SpriteKit adds about 2px of padding around all nodes and we need things to fit flush.
                    // unfortunately, this also causes things to "catch" on each other occasionally.
                    let path = CGPath(rect: CGRect(x: row.offset * 50, y: col.offset * 50, width: 48, height: 48), transform: nil)
                    let square = SKShapeNode(path: path)
                    square.userData = NSMutableDictionary()
                    square.userData?.setValue(path.getPathElementsPoints().asClockwise().centroid, forKey: "center")
                    square.lineWidth = 1
                    square.fillColor = color
                    square.strokeColor = .clear
                    let physicsBody = SKPhysicsBody(polygonFrom: path)

                    physicsBodies.append(physicsBody)
                    self.addChild(square)
                }
            }
        }
        self.physicsBody = SKPhysicsBody(bodies: physicsBodies)
        self.setup(color: color)
    }

    /// creates a tetronimo from a collection of paths. Used to create a tetronimo that replaces a piece that's been chopped up by a removed line.
    /// the orignal center point of each path is also saved into the userData of the nodes
    init(with childrenPaths: [(path: Path, center: CGPoint)], color: UIColor = currentTheme.randomColor) {
        super.init()
        let children = childrenPaths.compactMap{(path) -> (SKPhysicsBody, SKShapeNode)? in
            guard let physicsBody = SKPhysicsBody(polygonFrom: path.path.asCgPath()) as SKPhysicsBody?  else {
                // sometimes physics bodies fail to create from paths - we don't seem to miss any important nodes because of this.
                return nil
            }
            let diffNode = SKShapeNode(path: path.path.asCgPath())
            diffNode.userData = NSMutableDictionary()
            diffNode.userData?.setValue(path.path.asClockwise().centroid, forKey: "center")
            diffNode.fillColor = color
            diffNode.lineWidth = 1
            diffNode.strokeColor = .clear
            return (physicsBody, diffNode)
        }
        children.forEach { (physics, node) in
            self.addChild(node)
        }
        self.physicsBody = SKPhysicsBody(bodies: children.map{$0.0})
        self.setup(color: color)
    }

    private func setup(color: UIColor) {
        physicsBody?.affectedByGravity = false
        physicsBody?.categoryBitMask = tetCategory
        physicsBody?.contactTestBitMask = tetCategory | rowCategory
        physicsBody?.collisionBitMask = groundCategory | tetCategory | wallCategory
        physicsBody?.friction = 0.16
        physicsBody?.linearDamping = 0
        physicsBody?.density = 1
        physicsBody?.restitution = 0.05

        name = "tet"
        fillColor = color
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The active piece is the one controlled by the user. It needs to not be affected by gravity, have a downward velocity and other things.
    func makeActive() {
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.velocity = .init(dx: 0, dy: -100)
        // higher density so the active piece can push other pieces around.
        physicsBody?.density = 3
        physicsBody?.categoryBitMask = activeTetCategory
        physicsBody?.contactTestBitMask = groundCategory | tetCategory
        physicsBody?.collisionBitMask = groundCategory | tetCategory | wallCategory
        name = "activeTet"
    }

    func makeInactive() {
        name = "tet"
        physicsBody?.affectedByGravity = true
        physicsBody?.categoryBitMask = tetCategory
        physicsBody?.density = 1
    }
}
