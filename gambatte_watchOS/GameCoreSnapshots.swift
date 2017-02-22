//
//  GameCore.swift
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-03-04.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import CoreGraphics
import Gambatte_watchOS

extension GameCore {

	static let colorSpace = CGColorSpaceCreateDeviceRGB()
	
	public func createSnapshot(from buffer: UnsafeMutablePointer<UInt32>) -> UIImage? {

		let width = Int(kScreenWidth)
		let height = Int(kScreenHeight)

		guard
			let bitmapContext = CGContext(
				data: UnsafeMutableRawPointer(buffer),
				width: width,
				height: height,
				bitsPerComponent: 8,
				bytesPerRow: 4 * width,
				space: GameCore.colorSpace,
				bitmapInfo: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
			
			let cgImage = bitmapContext.makeImage()
			
			else {
				return nil
		}
		return UIImage(cgImage: cgImage)
	}
}
