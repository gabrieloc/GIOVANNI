//
//  GameLoader.swift
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
import WatchConnectivity

extension UserDefaults {
	
	enum Key: String {
		case lastPlayed
	}
	var lastPlayed: Game? {
		get {
			guard let info = dictionary(forKey: Key.lastPlayed.rawValue) else {
				return nil
			}
			return Game(dictionary: info)
		}
		set {
			if let game = newValue {
				let info = game.serialized
				set(info, forKey: Key.lastPlayed.rawValue)
			} else {
				removeObject(forKey: Key.lastPlayed.rawValue)
			}
		}
	}
}

public class GameLoader: NSObject {

	struct GameLoaderError: Error {
		var reason: String
	}
	
	let core: GameCore
	let documentDirectory: URL
	let session = WCSession.default()
	var activationState: WCSessionActivationState = .notActivated
	
	var activationCompletion: ((Error?) -> Void)?
	
	var gameResponse: ((String) -> Void)?
	
	static let shared = GameLoader()
	
	private override init() {
		
		documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		core = GameCore()
		core.workingDirectory = documentDirectory
		
		super.init()
	}
	
	deinit {
		session.delegate = nil
	}
	
	
	func activate(_ completion: @escaping ((Error?) -> Void)) {
		
		session.delegate = self
		if session.activationState != .activated {
			activationCompletion = completion
			session.activate()
		} else {
			activationCompletion = nil
			completion(nil)
		}
	}
	
	func requestGames(_ success: @escaping (([Game]) -> Void), failure: @escaping ((Error) -> Void)) {
		
		let replyHandler: (([String: Any]) -> Void) = { (response) in
			guard let gamesRaw = response["games"] as? [[String: Any]] else {
				failure(GameLoaderError(reason: "bad response"))
				return
			}
			let games = gamesRaw.flatMap { Game(dictionary: $0) }
			success(games)
		}

		session.sendMessage(["requestGames": 1], replyHandler: replyHandler, errorHandler: failure)
	}
	
	func loadGame(_ game: Game, _ success: @escaping ((GameCore) -> Void), failure: @escaping ((Error) -> Void)) {
		
		gameResponse = { [unowned self] (dataPath) in
			self.core.loadFile(atPath: dataPath, success: { (core) in
				UserDefaults.standard.lastPlayed = game
				success(core)
			}, failure: failure)
		}
		
		if let dataURL = cachedURL(for: game) {
			gameResponse!(dataURL.path)
		} else {
			session.sendMessage(["gamePath": game.path], replyHandler: nil, errorHandler: failure)
		}
	}
	
	
	func cachedURL(for game: Game) -> URL? {
		do {
			let contents = try FileManager.default.contentsOfDirectory(at: cacheURL!, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles])
			return contents.first(where: { $0.lastPathComponent.contains(game.name) })
		} catch {
			return nil
		}
	}
	
	var cacheURL: URL? {
		return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
	}
}

extension GameLoader: WCSessionDelegate {
	
	public func session(_ session: WCSession, didReceive file: WCSessionFile) {
		print("received \(file)")
		
		guard let response = gameResponse, let fileURL = file.fileURL else {
			return
		}
		do {
			let name = fileURL.lastPathComponent
			try FileManager.default.moveItem(at: fileURL, to: cacheURL!.appendingPathComponent(name))
		} catch (let error) {
			print("issue moving received file \(error)")
		}
		response(fileURL.path)
	}
	
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		
		self.activationState = activationState
		if let activationCompleted = activationCompletion {
			activationCompleted(error)
		}
	}
}
