//
//  ContentView.swift
//  BROKE
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .analytics:
                    NavigationStack { AnalyticsView() }
                case .settings:
                    NavigationStack { SettingsView() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 88)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selectedTab: $selectedTab)
                .ignoresSafeArea(.keyboard)
        }
        .background(theme.bg.ignoresSafeArea())
        .preferredColorScheme(theme.preferredColorScheme)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
        .environmentObject(PhotoService())
        .environmentObject(ThemeManager())
}
