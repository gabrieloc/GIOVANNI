//
//  ViewController.swift
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


import UIKit
import WatchConnectivity
import SafariServices

class ViewController: UIViewController {

	@IBAction func buttonSelected(_ sender: Any) {
		let url = URL(string: "https://twitter.com/_gabrieloc")!
		let safariViewController = SFSafariViewController(url: url)
		present(safariViewController, animated: true, completion: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
	
		prepareSession()
		
		if let documentsDirectory = FileManager.default.documentsDirectory {
			print("ROM URL: \(documentsDirectory)")
		}
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}
	


	func loadGames() -> [[String: String]]? {

		guard let documentsDirectory = FileManager.default.documentsDirectory else {
			return nil
		}
		
		do {
			let URLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
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
	
	func sendGamesList() {
		guard let games = loadGames() else {
			return
		}
		WCSession.default().sendMessage(["games": games], replyHandler: nil, errorHandler: nil)
	}
}
