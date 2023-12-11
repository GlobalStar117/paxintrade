import UIKit
import PushKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    internal var window: UIWindow?
    var callManager: CallManager?
    private let config = Config.default


    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize your CallManager instance
        callManager = CallManager()

        // Handle the incoming call when the notification is received
        if let notification = launchOptions?[.remoteNotification] as? [String: Any] {
            handleIncomingNotification(notification)
        }

        return true
    }
    
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Не удалось зарегистрироваться на уведомления: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
              print("Успешная регистрация на уведомления. Токен: \(token)")
              
              // Проверяем текущий статус разрешения на уведомления
              UNUserNotificationCenter.current().getNotificationSettings { settings in
                  if settings.authorizationStatus == .authorized {
                      // Если разрешение уже есть, то регистрируем устройство
                      self.sendDeviceTokenToServer(deviceToken: token)
                  } else {
                      // Если разрешение изменено на .authorized, регистрируем устройство
                      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                          if granted {
                              DispatchQueue.main.async {
                                  UIApplication.shared.registerForRemoteNotifications()
                                  self.sendDeviceTokenToServer(deviceToken: token)
                              }
                          } else if let error = error {
                              print("Не удалось получить разрешение на уведомления: \(error.localizedDescription)")
                          }
                      }
                  }
              }
        // Register for VoIP push notifications
        let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushRegistry.delegate = callManager?.pushNotificationDelegate
        pushRegistry.desiredPushTypes = [.voIP]
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle incoming push notification when the app is in the foreground
        handleIncomingNotification(userInfo)
    }

    private func handleIncomingNotification(_ userInfo: [AnyHashable: Any]) {
        guard let uuidString = userInfo["uuid"] as? String, let handle = userInfo["handle"] as? String else {
            return
        }

        let uuid = UUID(uuidString: uuidString)
        let id = uuid ?? UUID()

        // Report the incoming call
        callManager?.reportIncomingCall(id: id, handle: handle)
    }
    
    func sendDeviceTokenToServer(deviceToken: String) {
         guard let url = URL(string: "https://go.paxintrade.com/api/devices/ios") else {
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
