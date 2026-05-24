// BROKE/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)

            SlipReviewView()
                .tag(1)

            NavigationStack {
                AnalyticsView()
            }
            .tag(2)

            SettingsView()
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .bottom)  // top safe area respected; bottom ignored for full-bleed
        .preferredColorScheme(theme.preferredColorScheme)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 8)
        }
        .background(theme.background.ignoresSafeArea())
        .tint(theme.primary)
    }
}

#Preview {
    ContentView()
        .environmentObject(TransactionStore())
        .environmentObject(PhotoService())
        .environmentObject(ThemeManager())
}
