//
//  FloatingTabBar.swift
//  BROKE
//

import SwiftUI

enum AppTab: CaseIterable {
    case home, analytics, settings

    var label: String {
        switch self {
        case .home:      return "Home"
        case .analytics: return "Insights"
        case .settings:  return "Me"
        }
    }

    var icon: String {
        switch self {
        case .home:      return "house"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .settings:  return "person"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.10), radius: 15, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 14)
    }

    private func tabItem(_ tab: AppTab) -> some View {
        let isActive = selectedTab == tab
        return Button(action: { selectedTab = tab }) {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .medium))
                Text(tab.label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isActive ? theme.brand : Color.clear)
            )
            .foregroundColor(isActive ? theme.brandInk : theme.muted)
        }
        .buttonStyle(.plain)
    }
}
