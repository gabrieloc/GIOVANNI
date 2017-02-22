//
//  GameLoader.swift
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-02-24.
//  Copyright © 2017 Gabrieloc. All rights reserved.
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
		
		activationCompletion = completion
		session.delegate = self
		if session.activationState != .activated {
			session.activate()
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
		
		guard let response = gameResponse else {
			return
		}
		do {
			let name = file.fileURL.lastPathComponent
			try FileManager.default.moveItem(at: file.fileURL, to: cacheURL!.appendingPathComponent(name))
		} catch (let error) {
			print("issue moving received file \(error)")
		}
		response(file.fileURL.path)
	}
	
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		
		self.activationState = activationState
		if let activationCompleted = activationCompletion {
			activationCompleted(error)
		}
	}
}
