//
//  Transaction.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Foundation

enum TransactionType: String, Codable {
    case income
    case expense
}

enum TransactionCategory: String, Codable {
    case food = "1"
    case transportation = "2"
    case accommodation = "3"
    case entertainment = "4"
    case shopping = "5"
    case healthcare = "6"
    case necessary = "7"
    case gift = "8"
    case investment = "9"
    case tax = "10"
    case education = "11"
    case travel = "12"
    case insurance = "13"
    case other = "-1"
}

enum Bank: String, Codable {
    case kbank
    case ktb
    case scb
}

struct Transaction: Identifiable, Codable {
    var id = UUID()
    var refId: String?
    var amount: Double
    var description: String
    var date: Date
    var type: TransactionType
    var category: String
    var source: TransactionSource
    var categoryId: TransactionCategory?
    var bank: Bank?
    
    enum TransactionSource: String, Codable {
        case manual
        case scan
    }
}
