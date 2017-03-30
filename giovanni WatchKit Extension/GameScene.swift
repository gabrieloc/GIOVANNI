//
//  GameScene.swift
//  giovanni
//
//  Created by Gabriel O'Flaherty-Chan on 2017-03-29.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {

	let spriteNode = SKSpriteNode(imageNamed: "loading")
	var buffer: UnsafeMutablePointer<UInt32>?

	override init(size: CGSize) {
		super.init(size: size)

		spriteNode.size = size
		spriteNode.position = CGPoint(x: size.width * 0.5,
		                              y: size.height * 0.5)
		addChild(spriteNode)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var tick = 0
	override func update(_ currentTime: TimeInterval) {

		tick -= 1
		guard tick < 0, let buffer = buffer else {
			return
		}
		tick = 5

		let texture = createTexture(from: buffer)
		spriteNode.texture = texture
	}
}
