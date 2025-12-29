//
//  Transaction.swift
//  BROKE
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Foundation
import SwiftUI

enum TransactionType: String, Codable {
    case income
    case expense
}

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case food = "1"
    case transport = "2"
    case accommodation = "3"
    case entertainment = "4"
    case shopping = "5"
    case health = "6"
    case necessary = "7"
    case gift = "8"
    case investment = "9"
    case tax = "10"
    case education = "11"
    case travel = "12"
    case insurance = "13"
    case bills = "14"
    case others = "-1"

    static func from(string: String) -> ExpenseCategory {
        if let category = ExpenseCategory(rawValue: string) {
            return category
        }
        return .others
    }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .food: return NSLocalizedString("category.food", comment: "Food")
        case .transport: return NSLocalizedString("category.transport", comment: "Transport")
        case .shopping: return NSLocalizedString("category.shopping", comment: "Shopping")
        case .entertainment: return NSLocalizedString("category.entertainment", comment: "Entertainment")
        case .health: return NSLocalizedString("category.health", comment: "Health")
        case .education: return NSLocalizedString("category.education", comment: "Education")
        case .bills: return NSLocalizedString("category.bills", comment: "Bills")
        case .travel: return NSLocalizedString("category.travel", comment: "Travel")
        case .investment: return NSLocalizedString("category.investment", comment: "Investment")
        case .gift: return NSLocalizedString("category.gift", comment: "Gift")
        case .accommodation: return NSLocalizedString("category.accommodation", comment: "Accommodation")
        case .necessary: return NSLocalizedString("category.necessary", comment: "Necessary")
        case .tax: return NSLocalizedString("category.tax", comment: "Tax")
        case .insurance: return NSLocalizedString("category.insurance", comment: "Insurance")
        case .others: return NSLocalizedString("category.others", comment: "Others")
        default: return NSLocalizedString("category.others", comment: "Others")
        }
    }

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "film.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .bills: return "doc.text.fill"
        case .travel: return "airplane"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .gift: return "gift.fill"
        case .accommodation: return "house.fill"
        case .necessary: return "checklist"
        case .tax: return "banknote.fill"
        case .insurance: return "shield.fill"
        case .others: return "circle.grid.2x2.fill"
        default: return "circle.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .pink
        case .entertainment: return .purple
        case .health: return .red
        case .education: return .yellow
        case .bills: return .gray
        case .travel: return .cyan
        case .investment: return .mint
        case .gift: return .indigo
        case .accommodation: return .brown
        case .necessary: return .cyan
        case .tax: return .gray
        case .insurance: return .teal
        case .others: return .gray
        default: return .gray
        }
    }
}

enum IncomeCategory: String, CaseIterable, Codable, Identifiable {
    case salary = "1"
    case investment = "2"
    case gift = "3"
    case other = "-1"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .salary: return "Salary"
        case .investment: return "Investment"
        case .gift: return "Gift"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .salary: return "dollarsign.circle.fill"
        case .investment: return "chart.bar.fill"
        case .gift: return "gift.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .salary: return .green
        case .investment: return .blue
        case .gift: return .pink
        case .other: return .gray
        }
    }
}

// Bank enum is now defined in Core/Models/Bank.swift

struct SubTransaction: Identifiable, Codable {
    var id = UUID()
    var amount: Double
    var categoryId: ExpenseCategory
}

struct Transaction: Identifiable, Codable {
    var id = UUID()
    var refId: String?
    var amount: Double
    var description: String
    var date: Date
    var sender: String?
    var receiver: String?
    var type: TransactionType
    var source: TransactionSource
    var categoryId: ExpenseCategory?
    var incomeCategoryId: IncomeCategory?
    var bank: Bank?
    var imagePath: String?
    var subTransactions: [SubTransaction]? = nil

    enum TransactionSource: String, Codable {
        case manual
        case scan
    }
}
