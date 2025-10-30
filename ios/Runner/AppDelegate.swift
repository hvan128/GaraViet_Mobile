import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Firebase
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    
    // Set FCM messaging delegate
    Messaging.messaging().delegate = self
    
    // Configure FCM
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { granted, error in
          print("🔔 [iOS] Notification permission granted: \(granted)")
          if let error = error {
            print("❌ [iOS] Notification permission error: \(error)")
          }
        }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNs registration success
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("✅ [APNs] Successfully registered for remote notifications")
    Messaging.messaging().apnsToken = deviceToken
  }
  
  // Handle APNs registration failure
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ [APNs] Failed to register for remote notifications: \(error)")
  }
  
  // Handle notification when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    print("🔔 [iOS] Received notification in foreground")
    print("🔔 [iOS] Notification title: \(notification.request.content.title)")
    print("🔔 [iOS] Notification body: \(notification.request.content.body)")
    print("🔔 [iOS] Notification userInfo: \(notification.request.content.userInfo)")
    print("🔔 [iOS] Notification identifier: \(notification.request.identifier)")
    print("🔔 [iOS] Notification trigger: \(notification.request.trigger?.description ?? "nil")")
    
    // Parse và log payload data
    let userInfo = notification.request.content.userInfo
    if let data = userInfo["data"] as? [String: Any] {
      print("🔔 [iOS] Notification data payload: \(data)")
    }
    if let type = userInfo["type"] as? String {
      print("🔔 [iOS] Notification type: \(type)")
    }
    if let action = userInfo["action"] as? String {
      print("🔔 [iOS] Notification action: \(action)")
    }
    
    // Show notification even when app is in foreground
    completionHandler([.alert, .badge, .sound])
  }
  
  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    print("👆 [iOS] User tapped notification")
    print("👆 [iOS] Notification title: \(response.notification.request.content.title)")
    print("👆 [iOS] Notification body: \(response.notification.request.content.body)")
    print("👆 [iOS] Notification userInfo: \(response.notification.request.content.userInfo)")
    print("👆 [iOS] Notification identifier: \(response.notification.request.identifier)")
    print("👆 [iOS] Response action identifier: \(response.actionIdentifier)")
    
    // Parse và log payload data
    let userInfo = response.notification.request.content.userInfo
    if let data = userInfo["data"] as? [String: Any] {
      print("👆 [iOS] Notification data payload: \(data)")
    }
    if let type = userInfo["type"] as? String {
      print("👆 [iOS] Notification type: \(type)")
    }
    if let action = userInfo["action"] as? String {
      print("👆 [iOS] Notification action: \(action)")
    }
    if let roomId = userInfo["room_id"] as? String {
      print("👆 [iOS] Room ID: \(roomId)")
    }
    
    completionHandler()
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔥 [FCM] Registration token: \(fcmToken ?? "nil")")
    
    if let token = fcmToken {
      print("🔥 [FCM] Token length: \(token.count)")
      print("🔥 [FCM] Token prefix: \(String(token.prefix(20)))...")
    }
    
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
  
}
