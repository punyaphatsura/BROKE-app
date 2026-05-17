//
//  SlipBanner.swift
//  BROKE
//

import SwiftUI

struct SlipBanner: View {
    let slipCount: Int
    let onReview: () -> Void
    @EnvironmentObject var theme: ThemeManager

    private var speechText: String {
        switch theme.character {
        case .penguin:
            return slipCount == 1
                ? "I caught 1 slip for you! Tap Review to file it."
                : "I caught \(slipCount) slips for you! Tap Review to file them."
        case .dragon:
            return slipCount == 1
                ? "Rawr! I sniffed out 1 slip! Tap Review to file it."
                : "Rawr! I sniffed out \(slipCount) slips! Tap Review."
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Mascot tile
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.softBrand)
                    .frame(width: 44, height: 44)
                MascotView(size: 28)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(speechText)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Review button
            Button(action: onReview) {
                Text("Review")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.brandInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(theme.brand)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
}
