//
//  Meow_Jod_Clone_AppApp.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct Meow_Jod_Clone_AppApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject var transactionStore = TransactionStore()
    @StateObject var photoService = PhotoService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(transactionStore)
                .environmentObject(photoService)
        }
    }
}
