//
//  FileManagerAdditions.swift
//  giovanni
//
//  Created by Gabriel O'Flaherty-Chan on 2017-03-21.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import Foundation

extension String {
	var isValidROMExtension: Bool {
		return ["gb", "gbc", "zip"].contains(self)
	}
}

extension FileManager {
	
	enum FileError: LocalizedError {
		case invalidExtension
		
		public var errorDescription: String? {
			switch self {
			case .invalidExtension:
				return "Not a valid ROM file"
			}
			return nil
		}
	}
	
	var documentsDirectory: URL? {
		let directory: FileManager.SearchPathDirectory = .documentDirectory
		return FileManager.default.urls(for: directory, in: .userDomainMask).first as URL?
	}
	
	func receiveFile(at fileURL: URL, completion: ((String) -> Bool), failure: ((Error) -> Bool)) -> Bool {
		
		guard fileURL.pathExtension.isValidROMExtension else {
			return failure(FileError.invalidExtension)
		}
		
		do {
			let name = fileURL.lastPathComponent
			let destinationPath = documentsDirectory!.appendingPathComponent(name)
			try FileManager.default.moveItem(at: fileURL, to: destinationPath)
			return completion(name)
		} catch (let error) {
			return failure(error)
		}
	}
}
