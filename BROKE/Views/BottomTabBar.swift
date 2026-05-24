// BROKE/Views/BottomTabBar.swift
import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var theme: ThemeManager

    private struct TabItem {
        let tag: Int
        let label: String
        let icon: String
        let iconFilled: String
    }

    private let items: [TabItem] = [
        TabItem(tag: 0, label: "Home",     icon: "house",            iconFilled: "house.fill"),
        TabItem(tag: 1, label: "Slips",    icon: "doc.viewfinder",   iconFilled: "doc.viewfinder.fill"),
        TabItem(tag: 2, label: "Insights", icon: "chart.pie",        iconFilled: "chart.pie.fill"),
        TabItem(tag: 3, label: "Me",       icon: "person",           iconFilled: "person.fill"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.tag) { item in
                Button(action: { selectedTab = item.tag }) {
                    VStack(spacing: 3) {
                        Image(systemName: selectedTab == item.tag ? item.iconFilled : item.icon)
                            .font(.system(size: 22, weight: .medium))
                        Text(item.label)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(selectedTab == item.tag
                                  ? theme.primary
                                  : Color.clear)
                    )
                    .foregroundColor(selectedTab == item.tag
                                     ? theme.cardBackground
                                     : theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(theme.cardBackground)
                .shadow(color: theme.textPrimary.opacity(0.10),
                        radius: 16, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
    }
}
