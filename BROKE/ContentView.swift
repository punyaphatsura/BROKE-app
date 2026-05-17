// BROKE/ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                NavigationStack {
                    AnalyticsView()
                }
                .tag(1)

                SettingsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .preferredColorScheme(theme.preferredColorScheme)

            BottomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 24)
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
