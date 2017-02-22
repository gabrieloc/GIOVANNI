//
//  GameRow.swift
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-02-25.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import WatchKit

class InfoRow: NSObject {
	
	static let type = "Info"
	@IBOutlet var titleLabel: WKInterfaceLabel!
}

class GameRow: NSObject {
	
	static let type = "GameRow"
	@IBOutlet var titleLabel: WKInterfaceLabel!
}
