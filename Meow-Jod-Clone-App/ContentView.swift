//
//  ContentView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            ScannerView()
                .tabItem {
                    Label("Scan", systemImage: "doc.text.viewfinder")
                }
                .tag(1)
            
            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }.ignoresSafeArea()
    }
}

#Preview {
    ContentView().environmentObject(TransactionStore())
}
