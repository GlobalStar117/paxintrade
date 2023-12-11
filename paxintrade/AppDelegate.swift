//
//  AppDelegate.swift
//  paxintrade
//
//  Created by OneClick on 8/12/23.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Успешная регистрация на уведомления. Токен: \(token)")
        
        sendDeviceTokenToServer(deviceToken: token)

    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Не удалось зарегистрироваться на уведомления: \(error.localizedDescription)")
    }
    
    func sendDeviceTokenToServer(deviceToken: String) {
         guard let url = URL(string: "https://go.paxintrade.com/api/device") else {
             print("Ошибка формирования URL")
             return
         }

         var request = URLRequest(url: url)
         request.httpMethod = "POST"
         request.addValue("application/json", forHTTPHeaderField: "Content-Type")

         let parameters: [String: Any] = ["device": deviceToken]

         do {
             request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
         } catch {
             print("Ошибка сериализации JSON: \(error.localizedDescription)")
             return
         }

         let task = URLSession.shared.dataTask(with: request) { data, response, error in
             if let error = error {
                 print("Ошибка отправки на сервер: \(error.localizedDescription)")
                 return
             }

             guard let data = data else {
                 print("Пустой ответ от сервера")
                 return
             }

             do {
                 let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                 print("Ответ от сервера: \(jsonResponse)")
             } catch {
                 print("Ошибка десериализации JSON: \(error.localizedDescription)")
             }
         }

         task.resume()
     }

}
