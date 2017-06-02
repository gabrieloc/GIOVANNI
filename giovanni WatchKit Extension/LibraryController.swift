//
//  LibraryController.swift
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
import Foundation
import Gambatte_watchOS
import WatchConnectivity

class LibraryController: WKInterfaceController {
	
	var noGamesFound = false
	var games: [Game]? {
		didSet {
			if let games = games {
				noGamesFound = games.count == 0
				populateTable(with: games)
			}
		}
	}
	
	@IBOutlet weak var table: WKInterfaceTable!
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		reloadGames()
	}

	override func didAppear() {
		super.didAppear()

		if GameLoader.shared.core != nil {
			GameLoader.shared.core = nil
		}
	}
	
	override func willActivate() {
		super.willActivate()

		GameLoader.shared.gamesUpdated = { [unowned self] games in
			self.games = games
		}
		
		guard let cacheURL = GameLoader.shared.cacheURL else {
			return
		}
		print("WATCH ROM URL: , \(cacheURL.absoluteString)")
		// Auto-loads the last played game
//		if let game = UserDefaults.standard.lastPlayed {
//			presentGame(game)
//		}
	}
	
	override func didDeactivate() {
		super.didDeactivate()
		
		GameLoader.shared.gamesUpdated = nil
	}
	
	func reloadGames() {
		
		noGamesFound = false
		populateTable(with: [])
		
		let success: (([Game]) -> Void) = { [unowned self] games in
			self.games = games
		}
		
		let failure: ((Error) -> Void) = {
			[unowned self] (error) in
			self.noGamesFound = true
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
				info.refreshHandler = reloadGames
				info.refreshButton.setHidden(false)
				info.titleLabel.setText("Add games to your phone’s Documents folder from iTunes")
			} else {
				info.titleLabel.setText("Looking for games...")
				info.refreshButton.setHidden(true)
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

	override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
		return games![rowIndex - 1]
	}
}
