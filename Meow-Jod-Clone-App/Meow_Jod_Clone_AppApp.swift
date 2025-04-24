//
//  Meow_Jod_Clone_AppApp.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

@main
struct Meow_Jod_Clone_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(TransactionStore())
        }
    }
}
