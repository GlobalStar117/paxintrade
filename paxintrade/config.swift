//
//  config.swift
//  paxintrade
//
//  Created by OneClick on 10/12/23.
//

import Foundation

// Set this to the machine's address which runs the signaling server.
fileprivate let defaultSignalingServerUrl = URL(string: "wss://rtc.paxintrade.com/ws/")!

// We use Google's public stun servers.
fileprivate let defaultIceServers = ["stun:stun.l.google.com:19302",
                                     "stun:stun1.l.google.com:19302",
                                     "stun:stun2.l.google.com:19302",
                                     "stun:stun3.l.google.com:19302",
                                     "stun:stun4.l.google.com:19302"]

struct Config {
    let signalingServerUrl: URL
    let webRTCIceServers: [String]
    
    static let `default` = Config(signalingServerUrl: defaultSignalingServerUrl, webRTCIceServers: defaultIceServers)
}
