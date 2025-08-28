import UIKit
import Flutter
import Firebase
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  var flutterEngine: FlutterEngine?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Firebase configure - এইটা সবার আগে
    FirebaseApp.configure()
    
    // Google Sign In configure
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let clientId = plist["CLIENT_ID"] as? String {
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    flutterEngine = FlutterEngine(name: "my flutter engine")
    flutterEngine?.run()
    
    // Flutter plugin registry
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Google Sign In URL handling
  override func application(_ app: UIApplication,
                           open url: URL,
                           options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
}
