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
        // Initialize Firebase
        FirebaseApp.configure()

        // Google Sign-In configuration (read client id from GoogleService-Info.plist)
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        }

        // Register Flutter plugins
        GeneratedPluginRegistrant.register(with: self)

        // Set up Firebase Messaging delegate
        Messaging.messaging().delegate = self

        // Register for remote notifications (APNs)
        application.registerForRemoteNotifications()

        // Configure audio session
        configureAudioSession()

        // Request microphone permission
        requestMicrophonePermission()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - App Lifecycle Methods

    /// Called when app becomes active (foreground)
    override func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge count when app becomes active
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("✅ App became active - Badge cleared")
    }

    /// Called when app is about to enter foreground
    override func applicationWillEnterForeground(_ application: UIApplication) {
        // Clear badge count when entering foreground
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("✅ App entering foreground - Badge cleared")
    }

    // MARK: - APNs Registration

    /// Called when APNs token is successfully registered
    override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNs device token registered successfully")
        // Set APNs token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }

    /// Called when APNs registration fails
    override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNs registration failed: \(error.localizedDescription)")
    }

    // MARK: - Audio Configuration

    /// Configure audio session for recording and playback
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try audioSession.setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("⚠️ Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    /// Request microphone permission
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Microphone permission granted")
                } else {
                    print("⚠️ Microphone permission denied")
                }
            }
        }
    }

    // MARK: - Google Sign-In URL Handler

    /// Handle Google Sign-In URL
    override func application(_ app: UIApplication,
                              open url: URL,
                              options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle Google Sign-In URL
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        // Let Flutter handle other URLs
        return super.application(app, open: url, options: options)
    }

    // MARK: - Notification Handlers

    /// Handle notification when app is in foreground
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let title = notification.request.content.title
        let body = notification.request.content.body
        print("✅ Foreground notification received - Title: \(title), Body: \(body)")

        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }

    /// Handle notification tap
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let title = response.notification.request.content.title
        print("✅ Notification tapped - Title: \(title)")

        // Clear badge count when notification is tapped
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("✅ Badge cleared after notification tap")

        completionHandler()
    }
}

// MARK: - Firebase Messaging Delegate

extension AppDelegate: MessagingDelegate {

    /// Called when FCM registration token is received or refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("✅ FCM registration token received: \(token)")
        } else {
            print("⚠️ FCM registration token is nil")
        }

        // You can send this token to your backend server here if needed
        // For example: sendTokenToServer(token: fcmToken)
    }
}