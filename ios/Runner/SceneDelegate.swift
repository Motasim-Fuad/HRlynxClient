import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene,
             willConnectTo session: UISceneSession,
             options connectionOptions: UIScene.ConnectionOptions) {

    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)

    // AppDelegate থেকে FlutterEngine get করুন
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
          let flutterEngine = appDelegate.flutterEngine else {
      fatalError("Flutter Engine not found")
    }

    let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    window.rootViewController = flutterViewController
    self.window = window
    window.makeKeyAndVisible()
  }
}