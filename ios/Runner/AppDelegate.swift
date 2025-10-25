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
        // Firebase
        FirebaseApp.configure()

        // Google Sign-In (read client id from GoogleService-Info.plist)
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        }

        // Register plugins
        GeneratedPluginRegistrant.register(with: self)

        // ✅ CRITICAL: Set up Firebase Messaging delegate
        Messaging.messaging().delegate = self

        // ✅ CRITICAL: Register for remote notifications
        application.registerForRemoteNotifications()

        // Setup audio session
        configureAudioSession()

        // Request microphone permission
        requestMicrophonePermission()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ✅ CRITICAL: Handle APNs token registration
    override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNs token registered")
        Messaging.messaging().apnsToken = deviceToken
    }

    // ✅ CRITICAL: Handle APNs registration failure
    override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs registration failed: \(error.localizedDescription)")
    }

    // MARK: - Audio
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("⚠️ Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                print("Microphone permission granted: \(granted)")
            }
        }
    }

    // MARK: - Google Sign-In URL handler
    override func application(_ app: UIApplication,
                              open url: URL,
                              options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return super.application(app, open: url, options: options)
    }

    // MARK: - Notifications
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("✅ Foreground notification received: \(notification.request.content.title)")
        completionHandler([.alert, .badge, .sound])
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        print("✅ Notification tapped: \(response.notification.request.content.title)")
        completionHandler()
    }
}

// ✅ CRITICAL: Firebase Messaging delegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅ FCM registration token: \(String(describing: fcmToken))")
    }
}