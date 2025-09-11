import UIKit
import Flutter
import FirebaseCore
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

        // Notifications
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
        application.registerForRemoteNotifications()

        // Setup audio session
        configureAudioSession()

        // Request microphone permission
        requestMicrophonePermission()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
        completionHandler([.alert, .badge, .sound])
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
