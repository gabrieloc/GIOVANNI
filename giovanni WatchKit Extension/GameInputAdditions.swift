//
//  GameInputAdditions.swift
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
