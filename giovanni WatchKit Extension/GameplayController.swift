//
//  GameplayController.swift
//  GIOVANNI
//
//  Copyright (c) <2017>, Gabriel O'Flaherty-Chan
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. All advertising materials mentioning features or use of this software
//  must display the following acknowledgement:
//  This product includes software developed by skysent.
//  4. Neither the name of the skysent nor the
//  names of its contributors may be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY skysent ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL skysent BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import WatchKit
import SpriteKit
import Gambatte_watchOS

extension CGPoint {
	static func -(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
		return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
	}
}

class GameplayController: WKInterfaceController {
	@IBOutlet var scene: WKInterfaceSKScene!
	let spriteNode = SKSpriteNode(imageNamed: "loading")

	var panOrigin: CGPoint?
	let deadzone: CGFloat = 1

	@IBAction func tapUpdated(_ sender: WKTapGestureRecognizer) {
		pressInputOnce(.A)
	}

	@IBAction func panUpdated(_ sender: WKPanGestureRecognizer) {

		let direction = sender.translationInObject()

		switch sender.state {
		case .began:
			panOrigin = direction
		case .changed:
			if self.panOrigin == nil {
				self.panOrigin = direction
			}
			let panOrigin = self.panOrigin!
			let delta = direction - panOrigin

			if delta == .zero {
				return
			}

			if abs(delta.x) > abs(delta.y) {
				toggleInput = delta.x.sign == .plus ? .right : .left
			} else {
				toggleInput = delta.y.sign == .plus ? .down : .up
			}
		default:
			panOrigin = nil
			toggleInput = nil
		}
	}

	@IBAction func startSelected()	{ pressInputOnce(.start) }
	@IBAction func selectSelected() { pressInputOnce(.select) }
	@IBAction func BSelected()		{ pressInputOnce(.B) }

	@IBAction func loadSelected() {
		guard let core = loader.core else { return }
		core.runWhilePaused({ core.load(fromSlot: 0) })
	}

	@IBAction func saveSelected() {
		guard let core = loader.core else { return }
		core.runWhilePaused({ core.save(toSlot: 0) })
	}

	@IBAction func resetSelected() {
		loader.core?.resetEmulation()
	}

	@IBOutlet var ALabel: WKInterfaceLabel!
	@IBOutlet var DPadLabel: WKInterfaceLabel!

	var imageCache = NSCache<NSString, UIImage>()

	func updateDirectionalInputs() {

		guard let core = loader.core else {
			DPadLabel.setText(GameInput(rawValue: 0).displaySymbol)
			return
		}

		let input = core.activeInput.pointee
		let directionInput = GameInput(rawValue: Int(input))

		// This takes up too much cpu :(
		//		let image = inputImage(for: directionInput)
		//		dpadImage.setImage(image)

		// This is a far cheaper alternative
		let text = directionInput.displaySymbol
		DPadLabel.setText(text)
	}

	func inputImage(for input: GameInput) -> UIImage? {

		let key = NSString(string: "Dpad-\(input.rawValue)")
		if let image = imageCache.object(forKey: key) {
			return image
		}

		guard let image = UIImage.dpadImage(for: input) else {
			return nil
		}
		imageCache.setObject(image, forKey: key)
		return image
	}

	let loader = GameLoader.shared

	var tick = 0
	let refreshRate = 5;

	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		setTitle("ｘ")

		guard let game = context as? Game else {
			pop()
			return
		}

		crownSequencer.delegate = self
		crownSequencer.focus()

		var size = contentFrame.size
		size.height *= 0.8
		let scene = SKScene(size: size)

		spriteNode.size = size
		spriteNode.position = CGPoint(x: size.width * 0.5,
		                              y: size.height * 0.5)
		scene.addChild(spriteNode)
		self.scene.presentScene(scene)

		let success: ((GameCore) -> Void) = { [unowned self] (core) in
			core.didRender = { [weak self] buffer in
				guard let s = self else {
					return
				}
				s.updateSnapshotIfNeeded(with: buffer)
			}
		}

		let failureHandler: ((Error) -> Void) = { [unowned self] (error) in
			print("error loading game \(error)")
			self.presentAlert(withTitle: "There was an issue loading this game", message: nil, preferredStyle: .alert, actions: [
				WKAlertAction(title: "Close", style: .default, handler: { [unowned self] in
					self.pop()
				})
				])
		}

		loader.loadGame(game, success, failure: failureHandler)

		(GameInput.directionalInputs + [GameInput.A]).forEach {
			self.setInputSelected($0, selected: false)
		}
	}

	override func willActivate() {
		super.willActivate()
//		loadSelected()
	}

	override func didDeactivate() {
		super.didDeactivate()
		loader.core?.saveSavedata()
//		saveSelected()
	}

	var lastSnapshot: UIImage?

	func updateSnapshotIfNeeded(with buffer: UnsafeMutablePointer<UInt32>) {

		tick += 1
		if tick < refreshRate || loader.core == nil {
			return
		}

		let texture = createTexture(from: buffer)
		texture.preload {
			self.spriteNode.texture = texture
		}

		tick = 0
	}

	// MARK: Input

	var toggleInput: GameInput? {

		didSet {
			if let oldInput = oldValue {
				setInputSelected(oldInput, selected: false)
			}
			if let newInput = toggleInput {
				setInputSelected(newInput, selected: true)
			}
		}
	}

	func setInputSelected(_ input: GameInput, selected: Bool) {

		if let core = loader.core {
			core.update(input, selected: selected)
		}

		if input.isDirectional {
			updateDirectionalInputs()
		} else if input == .A {
			let alpha: CGFloat = selected ? 1.0 : 0.5
			ALabel.setAlpha(alpha)
		}
	}

	var inputTimers = [GameInput: Timer]()

	func pressInputOnce(_ input: GameInput) {
		setInputSelected(input, selected: true)
		if let timer = inputTimers.first(where: { $0.key == input })?.value {
			timer.invalidate()
		}
		let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] (_) in
			guard let s = self else { return }
			s.setInputSelected(input, selected: false)
		}
		inputTimers[input] = timer
	}
}

extension GameplayController: WKCrownDelegate {

	func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?) {
		toggleInput = nil
	}

	func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
		if rotationalDelta == 0 {
			return
		}
		let input: GameInput = rotationalDelta > 0 ? .up : .down
		toggleInput = input
	}
}
