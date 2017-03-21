//
//  FileManagerAdditions.swift
//  giovanni
//
//  Created by Gabriel O'Flaherty-Chan on 2017-03-21.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import Foundation

extension FileManager {
	
	var documentsDirectory: URL? {
		let directory: FileManager.SearchPathDirectory = .documentDirectory
		return FileManager.default.urls(for: directory, in: .userDomainMask).first as URL?
	}
	
	func receiveFile(at fileURL: URL, completion: ((String) -> Bool), failure: ((Error) -> Bool)) -> Bool {
		
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
