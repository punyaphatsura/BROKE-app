//
//  BalanceCard.swift
//  BROKE
//

import SwiftUI

struct BalanceCard: View {
    let netAmount: Double
    let incomeAmount: Double
    let expenseAmount: Double
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 140, height: 140)
                .offset(x: 30, y: -30)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 60, height: 60)
                .offset(x: -20, y: 60)

            VStack(alignment: .leading, spacing: 16) {
                Text("NET THIS MONTH")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                    .foregroundColor(theme.brandInk.opacity(0.9))

                // Big balance number
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("฿")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.brandInk)
                    Text(formattedWhole)
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.brandInk)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    if !formattedDecimal.isEmpty {
                        Text("." + formattedDecimal)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.brandInk.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // In / Out row
                HStack(spacing: 8) {
                    inOutPill(label: "IN", amount: incomeAmount, arrow: "↓")
                    inOutPill(label: "OUT", amount: expenseAmount, arrow: "↑")
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(theme.brand)
        )
        .clipped()
        .padding(.horizontal, 16)
    }

    private func inOutPill(label: String, amount: Double, arrow: String) -> some View {
        HStack(spacing: 6) {
            Text(arrow)
                .font(.system(size: 12, weight: .semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(0.4)
                Text("฿\(Int(amount).formattedWithSeparator)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
        }
        .foregroundColor(theme.brandInk)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.18))
        )
    }

    private var formattedWhole: String {
        let absVal = abs(netAmount)
        let whole = Int(absVal)
        let prefix = netAmount < 0 ? "-" : ""
        return prefix + NumberFormatter.localizedString(from: NSNumber(value: whole), number: .decimal)
    }

    private var formattedDecimal: String {
        let absVal = abs(netAmount)
        let decimal = absVal - Double(Int(absVal))
        guard decimal > 0.005 else { return "" }
        return String(format: "%02d", Int(decimal * 100))
    }
}
