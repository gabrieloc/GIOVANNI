//
//  GameInputAdditions.swift
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-03-07.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import Foundation
import Gambatte_watchOS
import UIKit

extension GameInput: Hashable {

	public var hashValue: Int {
		return rawValue
	}

	var isDirectional: Bool {
		return GameInput.directionalInputs.contains(self)
	}
	
	static var directionalInputs: [GameInput] {
		return [.up, .right, .down, .left]
	}
	
	var displaySymbol: String {
		
		switch self {
		case GameInput.up:		return "▲"
		case GameInput.right:	return "▶︎"
		case GameInput.down:	return "▼"
		case GameInput.left:	return "◀"
		default:				return "●"
		}
	}
}

extension UIImage {
	
	func equalPixels(to image: UIImage) -> Bool {
		return UIImagePNGRepresentation(self) == UIImagePNGRepresentation(image)
	}
	
	static func dpadImage(for direction: GameInput) -> UIImage? {
		
		let width: CGFloat = 4.0
		let size = CGSize(width: 20, height: 20)
		let rect = CGRect(origin: .zero, size: size)
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		
		GameInput.directionalInputs.forEach { input in
			
			let path = UIBezierPath()
			
			switch input {
			case GameInput.up:
				path.move(to: CGPoint(x: rect.midX, y: rect.minY))
				path.addLine(to: CGPoint(x: rect.midX, y: rect.midY - width))
			case GameInput.right:
				path.move(to: CGPoint(x: rect.midX + width, y: rect.midY))
				path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
			case GameInput.down:
				path.move(to: CGPoint(x: rect.midX, y: rect.midY + width))
				path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
			case GameInput.left:
				path.move(to: CGPoint(x: rect.minX, y: rect.midY))
				path.addLine(to: CGPoint(x: rect.midX - width, y: rect.midY))
			default:
				break
			}
			
			path.lineWidth = width
			let color = direction.contains(input) ? UIColor.white : UIColor.white.withAlphaComponent(0.5)
			color.setStroke()
			path.stroke()
		}
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
}
