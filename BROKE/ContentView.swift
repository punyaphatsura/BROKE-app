//
//  ContentView.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            NavigationStack {
                AnalyticsView()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.pie.fill")
            }
            .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(theme.primary)
        .ignoresSafeArea()
        .preferredColorScheme(theme.preferredColorScheme)
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
        .environmentObject(PhotoService())
        .environmentObject(ThemeManager())
}
