import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import UserNotifications
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        do {
            FirebaseApp.configure()
            print("Firebase configured")
        } catch {
            print("Firebase config failed: \(error.localizedDescription)")
        }

        configureGoogleSignIn()
        GeneratedPluginRegistrant.register(with: self)
        print("Flutter plugins registered")
        Messaging.messaging().delegate = self
        registerForPushNotifications(application)
        print("App launch complete")

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Google Sign-In setup
    private func configureGoogleSignIn() {
        do {
            guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let plist = NSDictionary(contentsOfFile: path),
                  let clientId = plist["CLIENT_ID"] as? String else {
                print("Google config not found")
                return
            }

            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
            print("Google Sign-In configured")
        } catch {
            print("Google config error: \(error.localizedDescription)")
        }
    }

    // Request notification permission
    private func registerForPushNotifications(_ application: UIApplication) {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().delegate = self

            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, error in
                if let error = error {
                    print("Notification error: \(error.localizedDescription)")
                    return
                }

                if granted {
                    print("Notification permission granted")
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    print("Notification permission denied")
                }
            }
        }
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("App active - Badge cleared")
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("App foreground - Badge cleared")
    }

    // APNs device token
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("APNs token registered")
        Messaging.messaging().apnsToken = deviceToken
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNs failed: \(error.localizedDescription)")
    }

    // Google Sign-In URL handler
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return super.application(app, open: url, options: options)
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let title = notification.request.content.title
        print("Foreground notification: \(title)")
        completionHandler([.banner, .badge, .sound])
    }

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let title = response.notification.request.content.title
        print("Notification tapped: \(title)")
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler()
    }
}

// FCM token delegate
extension AppDelegate: MessagingDelegate {

    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        if let token = fcmToken {
            print("FCM token: \(token)")
        } else {
            print("FCM token is nil")
        }
    }
}
