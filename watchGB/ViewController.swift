//
//  ViewController.swift
//  watchGB
//
//  Created by Gabriel O'Flaherty-Chan on 2017-02-22.
//  Copyright © 2017 Gabrieloc. All rights reserved.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
	
		prepareSession()
	}
	
	var documentsDirectory: URL? {
		let directory: FileManager.SearchPathDirectory = .documentDirectory
		return FileManager.default.urls(for: directory, in: .userDomainMask).first as URL?
	}

	func loadGames() -> [[String: String]]? {

		guard let documentsDirectory = documentsDirectory else {
			return nil
		}
		
		do {
			let URLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
			return encodeFiles(with: URLs)
		} catch {
			return nil
		}
	}
	
	func encodeFiles(with URLs: [URL]) -> [[String: String]] {
		return URLs.reduce([[String: String]]()) {
			
			var games = $0.0
			
			let path = $0.1
			let name = path
				.lastPathComponent
				.components(separatedBy: ".")
				.dropLast()
				.joined()
			
			let game: [String: String] = [
				"name": name,
				"path": path.absoluteString
			]
			games.append(game)
			return games
		}
	}
}

extension ViewController: WCSessionDelegate {

	func prepareSession() {
		
		let session = WCSession.default()
		session.delegate = self
		if session.activationState != .activated {
			session.activate()
		}
	}

	public func sessionDidDeactivate(_ session: WCSession) {
		//
	}

	public func sessionDidBecomeInactive(_ session: WCSession) {
		//
	}

	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print(activationState)
	}
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		
		guard let path = message["gamePath"] as? String else {
			return
		}

		
		let url = URL(string: path)!
		session.transferFile(url, metadata: nil)
	}
	
	func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		if let _ = message["requestGames"] {
			guard let games = loadGames() else {
				return
			}
			print("replying with \(games)")
			replyHandler(["games": games])
		}
	}
	
}
