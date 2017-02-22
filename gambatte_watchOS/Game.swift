//
//  Game.swift
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-02-25.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import Foundation

public struct Game {
	
	public let name: String
	public let path: String
	
	public init?(dictionary: [String: Any]) {
		guard let name = dictionary["name"] as? String,
		 let path = dictionary["path"] as? String
			else {
				return nil
		}
		
		self.name = name
		self.path = path
	}
	
	var serialized: [String: Any] {
		return ["name": name, "path": path]
	}
}
