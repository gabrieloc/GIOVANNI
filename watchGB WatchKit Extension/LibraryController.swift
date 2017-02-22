//
//  LibraryController.swift
//  watchGB WatchKit Extension
//
//  Created by Gabriel O'Flaherty-Chan on 2017-02-22.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import WatchKit
import Foundation
import Gambatte_watchOS
import WatchConnectivity

class LibraryController: WKInterfaceController {
	
	var noGamesFound = false
	var games: [Game]? {
		didSet {
			if let games = games {
				populateTable(with: games)
			}
		}
	}
	
	@IBOutlet weak var table: WKInterfaceTable!
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		reloadGames()
	}
	override func willActivate() {
		super.willActivate()

//		if let game = UserDefaults.standard.lastPlayed {
//			presentGame(game)
//		}
	}
	
	func reloadGames() {
		
		populateTable(with: [])
		
		let success: (([Game]) -> Void) = { [unowned self] games in
			self.noGamesFound = games.count == 0
			self.games = games
		}
		
		let failure: ((Error) -> Void) = {
			[unowned self] (error) in
			self.presentAlert(withTitle: "Couldn't Reload Games", message: error.localizedDescription, preferredStyle: .alert, actions: [
				WKAlertAction(title: "Retry", style: .default, handler: { [unowned self] in self.reloadGames() }),
				WKAlertAction(title: "Close", style: .default, handler: {})])
		}
		
		let loader = GameLoader.shared
		loader.activate { (error) in
			if let error = error {
				failure(error)
			} else {
				loader.requestGames(success, failure: failure)
			}
		}
	}
	
	func populateTable(with games: [Game]) {
		
		var rowTypes = ["Header"]
		var offset = 1
		
		if noGamesFound || games.count == 0 {
			rowTypes += [InfoRow.type]
			offset = 2
		}
		
		rowTypes += games.map { _ in GameRow.type }
		table.setRowTypes(rowTypes)
		
		if let info = table.rowController(at: 1) as? InfoRow {
			if noGamesFound {
				info.titleLabel.setText("Add games to your phone’s Documents folder from iTunes")
			} else {
				info.titleLabel.setText("Loading...")
			}
		}
		
		for index in 0..<games.count {
			guard let row = table.rowController(at: index + offset) as? GameRow else {
				break
			}
			let game = games[index]
			row.titleLabel.setText(game.name)
		}
	}
	
	func presentGame(_ game: Game) {
		pushController(withName: "GamePlay", context: game)
	}
	
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		let game = games![rowIndex - 1]
		presentGame(game)
	}
}
