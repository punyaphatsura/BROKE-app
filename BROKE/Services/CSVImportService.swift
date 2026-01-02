//
//  CSVImportService.swift
//  BROKE
//
//  Created by Assistant on 29/12/2568 BE.
//

import Foundation

class CSVImportService {
    // "วันที่", "เวลา", "ประเภท", "หมวดหมู่", "แท็ก", "จำนวน", "โน๊ต", "ช่องทางจ่าย", "จ่ายจาก", "ธนาคารผู้รับ", "ผู้รับ"
    //  0       1       2         3          4       5        6        7            8          9            10

    func parseCSV(content: String) async throws -> [SlipData] {
        var results: [SlipData] = []
        let rows = content.components(separatedBy: .newlines)

        for (index, row) in rows.enumerated() {
            if row.trimmingCharacters(in: .whitespaces).isEmpty { continue }

            let columns = parseCSVRow(row)
            guard columns.count >= 6 else { continue } // Min requirement: Date, Amount

            // Check for header
            if index == 0, columns[0].contains("วันที่") {
                continue
            }

            // Parse Date & Time
            let dateStr = columns[0]
            let timeStr = columns.count > 1 ? columns[1] : "00:00"
            let dateTimeString = "\(dateStr) \(timeStr)"
            let formattedDate = convertToISO(dateStr: dateTimeString)

            // Parse Amount (handle negative values for expenses)
            // Example: -20 -> 20.0
            var amountStr = columns.count > 5 ? columns[5].replacingOccurrences(of: ",", with: "") : "0"
            if let amountDouble = Double(amountStr) {
                amountStr = String(abs(amountDouble))
            }

            // Parse Type and Category
            // Column 2: Type ("รายจ่าย" = expense, "รายรับ" = income, "ย้ายเงิน" = transfer)
            let typeStr = columns.count > 2 ? columns[2] : "รายจ่าย"
            var type = "expense"
            if typeStr == "รายรับ" { type = "income" }
            else if typeStr == "ย้ายเงิน" { type = "transfer" }

            // Column 3: Category
            // Pass this as a hint to SlipData
            let categoryStr = columns.count > 3 ? columns[3].replacingOccurrences(of: "\"", with: "") : ""

            // Receiver / Note
            let receiver = columns.count > 10 ? columns[10] : (columns.count > 6 ? columns[6] : "-")
            let sender = columns.count > 8 ? columns[8] : "-"
            let bank = columns.count > 9 ? columns[9] : "Unknown"

            // Construct SlipData dictionary
            let dict: [String: String] = [
                "bank": bank.isEmpty ? "Unknown" : bank,
                "date": formattedDate,
                "sender": sender.isEmpty ? "-" : sender,
                "receiver": receiver.isEmpty ? "-" : receiver,
                "amount": amountStr,
                "refId": UUID().uuidString,
                "categoryHint": categoryStr,
                "typeHint": type,
            ]

            results.append(SlipData(dictionary: dict))
        }

        return results
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var inQuotes = false

        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == ",", !inQuotes {
                result.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField.trimmingCharacters(in: .whitespaces))
        return result
    }

    private func convertToISO(dateStr: String) -> String {
        let formatters = [
            "d/M/yyyy HH:mm",
            "dd/MM/yyyy HH:mm",
            "yyyy-MM-dd HH:mm",
            "d/M/yyyy HH:mm:ss",
        ]

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        outputFormatter.calendar = Calendar(identifier: .gregorian)

        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.calendar = Calendar(identifier: .gregorian)
            if let date = formatter.date(from: dateStr) {
                return outputFormatter.string(from: date)
            }

            formatter.locale = Locale(identifier: "th_TH")
            if let date = formatter.date(from: dateStr) {
                return outputFormatter.string(from: date)
            }
        }
        return dateStr
    }
}
