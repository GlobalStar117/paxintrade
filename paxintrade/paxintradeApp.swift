//
//  paxintrade.swift
//  paxintrade
//
//  Created by ANDREI LEONOV on 14/7/23.
//

import SwiftUI

@main
struct paxintradeApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView().onAppear {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else if let error = error {
                        print("Не удалось получить разрешение на уведомления: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
