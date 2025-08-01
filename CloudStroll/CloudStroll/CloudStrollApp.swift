//
//  CloudStrollApp.swift
//  CloudStroll
//
//  Created by Amey Sunu on 28/07/2025.
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
struct CloudStrollApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var loginCtrl = LoginController()
    
    var body: some Scene {
        WindowGroup {
            if(loginCtrl.isSignedIn){
                HomeView(loginCtrl: loginCtrl)
            } else {
                Login(loginCtrl: loginCtrl)
            }
        }
    }
}
