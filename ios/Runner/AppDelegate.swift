import Flutter
import UIKit

// 1) Add the flutter_local_notifications import:
import flutter_local_notifications

@main // Changed here from @UIApplicationMain to @main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // 2) Register the pluginRegistrantCallback for local notifications:
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }
        
        // --- Existing code for your MethodChannel setup ---
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "gallery_saver",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "saveImageToGallery" {
                guard let imageData = call.arguments as? FlutterStandardTypedData else {
                    result(
                        FlutterError(
                            code: "INVALID_DATA",
                            message: "Image data not found",
                            details: nil
                        )
                    )
                    return
                }
                
                guard let uiImage = UIImage(data: imageData.data) else {
                    result(
                        FlutterError(
                            code: "INVALID_IMAGE",
                            message: "Could not convert data to UIImage",
                            details: nil
                        )
                    )
                    return
                }
                
                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                result("success")
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        // --- End existing MethodChannel code ---
        
        GeneratedPluginRegistrant.register(with: self)
        
        // 3) If iOS 10.0 or newer, set the UNUserNotificationCenter delegate:
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        
        // Continue with the usual Flutter setup:
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
