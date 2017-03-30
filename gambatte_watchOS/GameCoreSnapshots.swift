//
//  GameCore.swift
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

import CoreGraphics
import Gambatte_watchOS
import SpriteKit

extension GameplayController {
	
	static let colorSpace = CGColorSpaceCreateDeviceRGB()
	static let screenWidth = Int(kScreenWidth)
	static let screenHeight = Int(kScreenHeight)
	
	public func createSnapshot(from buffer: UnsafeMutablePointer<UInt32>) -> UIImage? {
		
		guard
			let bitmapContext = CGContext(
				data: UnsafeMutableRawPointer(buffer),
				width: GameplayController.screenWidth,
				height: GameplayController.screenHeight,
				bitsPerComponent: 8,
				bytesPerRow: MemoryLayout<UInt32>.size * GameplayController.screenWidth,
				space: GameplayController.colorSpace,
				bitmapInfo: CGImageByteOrderInfo.order32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
			
			let cgImage = bitmapContext.makeImage()
			
			else {
				return nil
		}
		return UIImage(cgImage: cgImage)
	}
	
	public func createTexture(from buffer: UnsafeMutablePointer<UInt32>) -> SKTexture {
		
		let size = CGSize(width: GameplayController.screenWidth,
		                  height: GameplayController.screenHeight)
		let data = createData(from: buffer)
		let texture = SKTexture(data: data, size: size, flipped: true)
		texture.filteringMode = .nearest
		return texture
	}
	
	fileprivate func createData(from buffer: UnsafeMutablePointer<UInt32>) -> Data {
		
		let count = Int(kScreenHeight * kScreenWidth) * MemoryLayout<UInt32>.size
		let bufferPointer =  UnsafeBufferPointer(start: buffer, count: count)
		return Data(buffer: bufferPointer)
	}

	// Use this for debugging. Will output a file to the app's documents directory.
	
	func logBuffer(_ buffer: UnsafeMutablePointer<UInt32>) {
		
		let data = createData(from: buffer)
		let count = data.count
		var bytes = [UInt8](repeating: 0, count: count)
		data.copyBytes(to: &bytes, count: count)
		
		let formatter = DateFormatter()
		formatter.dateStyle = .full
		let url = GameLoader.shared.cacheURL!.appendingPathComponent(formatter.string(from: Date()))
		
		do {
			try data.write(to: url)
		} catch {
		}
		print("Wrote data to \(url)")
	}
}
