//
//  SlipData.swift
//  BROKE
//
//  Created by Assistant on 30/11/2568 BE.
//

import Foundation

// MARK: - Slip Data Structure
struct SlipData {
    let bank: String
    let date: String
    let sender: String
    let receiver: String
    let amount: String
    let refId: String
    var imagePath: String? // Added imagePath
    var categoryHint: String? // Added to pass category from CSV
    var typeHint: String? // Added to pass type from CSV

    init(dictionary: [String: String]) {
        self.bank = dictionary["bank"] ?? "Unknown"
        self.date = dictionary["date"] ?? "-"
        self.sender = dictionary["sender"] ?? "-"
        self.receiver = dictionary["receiver"] ?? "-"
        self.amount = dictionary["amount"] ?? "-"
        self.refId = dictionary["refId"] ?? "-"
        self.categoryHint = dictionary["categoryHint"]
        self.typeHint = dictionary["typeHint"]
        self.imagePath = nil
    }
    
    var parsedAmount: Double? {
        let cleanAmount = amount
            .replacingOccurrences(of: " บาท", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        return Double(cleanAmount)
    }
    
    var parsedDate: Date? {
        let dateFormatter = DateFormatter()
        
        // Try different date formats
        let formats = [
            "d MMM yyyy",
            "dd MMM yyyy",
            "d MMM yy",
            "dd MMM yy",
            "dd/MM/yyyy",
            "dd/MM/yy",
            "yyyy-MM-dd",
            "dd-MM-yyyy",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        let thaiMonths = [
            "ม.ค.": "Jan", "ก.พ.": "Feb", "มี.ค.": "Mar", "เม.ย.": "Apr",
            "พ.ค.": "May", "มิ.ย.": "Jun", "ก.ค.": "Jul", "ส.ค.": "Aug",
            "ก.ย.": "Sep", "ต.ค.": "Oct", "พ.ย.": "Nov", "ธ.ค.": "Dec"
        ]
        
        var dateString = date
        
        // Convert Thai months to English
        for (thai, english) in thaiMonths {
            dateString = dateString.replacingOccurrences(of: thai, with: english)
        }
        
        // Try parsing with different formats
        for format in formats {
            dateFormatter.dateFormat = format
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let parsedDate = dateFormatter.date(from: dateString) {
                return parsedDate
            }
        }
        
        return nil
    }
    
    var detectedBank: Bank? {
        return Bank.from(string: bank)
    }
}
