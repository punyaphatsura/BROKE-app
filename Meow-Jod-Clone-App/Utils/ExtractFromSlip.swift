//
//  ExtractFromSlip.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 1/5/2568 BE.
//

import Foundation

struct ExtractFromSlip {
    static private func extractScb(from text: String) -> [String: String] {
        let bank     = Bank.SCB.rawValue
        var date     = "-"
        var sender   = "-"
        var receiver = "-"
        var amount   = "-"
        var refId    = "-"
        
        // Precompile the two regexes we need:
        let dateRegex = try! NSRegularExpression(
          pattern: #"(\d{1,2}) (ม\.?ค\.?|ก\.?พ\.?|มี\.?ค\.?|เม\.?ย\.?|พ\.?ค\.?|มิ\.?ย\.?|ก\.?ค\.?|ส\.?ค\.?|ก\.?ย\.?|ต\.?ค\.?|พ\.?ย\.?|ธ\.?ค\.?) (\d{2,4}) - (\d{2}:\d{2})"#,
          options: []
        )
        let refRegex = try! NSRegularExpression(
          pattern: #"รหัสอ้างอิง:\s*([A-Za-z0-9]+)"#,
          options: []
        )
        
        let isSpecialCase = text.contains("ข้อมูลเพิ่มเติมจากผู้ให้บริการ")

        // Break into mutable lines
        let lines = text.components(separatedBy: "\n")

        for i in 0..<lines.count {
            let line = lines[i]

            // 1) Date line
            if let m = dateRegex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {
                let day     = String(line[Range(m.range(at: 1), in: line)!])
                let month   = String(line[Range(m.range(at: 2), in: line)!])
                let year    = String(line[Range(m.range(at: 3), in: line)!])

                // Reformat date if needed
                date = "\(day) \(month) \(year)"
                continue
            }

            // 2) Reference ID line
            if let m = refRegex.firstMatch(in: line, options: [], range: .init(location: 0, length: line.utf16.count)) {
                let range = Range(m.range(at: 1), in: line)!
                let refIdTemp = String(line[range])
                refId = refIdTemp
                continue
            }

            // 3) Sender & Receiver via the fixed marker "ไปยัง"
            if line.trimmingCharacters(in: .whitespaces) == "ไปยัง" {
                // sender is the very next line
                if i+1 < lines.count {
                    sender = lines[i+1]
                }
                if !isSpecialCase {
                    // receiver is two lines after that (skip the sender's account line)
                    if i+3 < lines.count {
                        receiver = lines[i+3]
                    }
                }
                continue
            }
            
            // Special Case
            if isSpecialCase {
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("ข้อมูลเพิ่มเติมจากผู้ให้บริการ") {
                    if i+1 < lines.count {
                        receiver = lines[i+1]
                    }
                    if i+2 < lines.count {
                        amount = lines[i+2]
                    }
                    continue
                }
            }

            // 4) Amount block
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("จำนวนเงิน") {
                if i+1 < lines.count {
                    amount = lines[i+1]
                }
                continue
            }
        }

        receiver = receiver.replacingOccurrences(of: "0 ", with: "")

        return [
            "bank":     bank,
            "date":     date,
            "sender":   sender,
            "receiver": receiver,
            "amount":   amount,
            "refId":    refId
        ]
    }
    
    static private func extractKbank(from text: String) -> [String: String] {
        let bank     = Bank.KBANK.rawValue
        var date     = "-"
        var sender   = "-"
        var receiver = "-"
        var amount   = "-"
        var refId    = "-"
        
        // Precompile the two regexes we need:
        let dateRegex = try! NSRegularExpression(
          pattern: #"(\d{1,2}) (ม\.?ค\.?|ก\.?พ\.?|มี\.?ค\.?|เม\.?ย\.?|พ\.?ค\.?|มิ\.?ย\.?|ก\.?ค\.?|ส\.?ค\.?|ก\.?ย\.?|ต\.?ค\.?|พ\.?ย\.?|ธ\.?ค\.?) (\d{2,4}) (\d{2}:\d{2})"#,
          options: []
        )
        
        let replacedText = text.replacingOccurrences(of: "จ่ายละจิง\n", with: "")
            .replacingOccurrences(of: "\nPrompt\nPay", with: "\nPrompt Pay").replacingOccurrences(of: "\nจำนวน:", with: "").replacingOccurrences(of: "\nค่าธรรมเนียม:", with: "").replacingOccurrences(of: "\n0.00 บาท", with: "").replacingOccurrences(of: "\nสแกนตรวจสอบสลิป", with: "").replacingOccurrences(of: "\nK+", with: "").replacingOccurrences(of: "\n0 บาท", with: "")
        let lines = replacedText.components(separatedBy: "\n")
        
        // 2. Date & Time from line 1
        if lines.count > 1 {
                let dateTimeLine = lines[1]
                let range = NSRange(dateTimeLine.startIndex..<dateTimeLine.endIndex, in: dateTimeLine)
                if let match = dateRegex.firstMatch(in: dateTimeLine, options: [], range: range) {
                    let day = String(dateTimeLine[Range(match.range(at: 1), in: dateTimeLine)!])
                    let month = String(dateTimeLine[Range(match.range(at: 2), in: dateTimeLine)!])
                    let year = String(dateTimeLine[Range(match.range(at: 3), in: dateTimeLine)!])
                    date = "\(day) \(month) \(year)"
                }
            }
        
        // 3. Sender
        if lines.count > 2 {
            sender = lines[2]
        }

        // 4. Ref ID (เลขที่รายการ:) is usually 2 lines after that marker
        if let refIndex = lines.firstIndex(where: { $0.contains("เลขที่รายการ") }) {
            if refIndex + 1 < lines.count {
                refId = lines[refIndex + 1]
            }
        }
        
        if lines.count > 6 {
            receiver = lines[6]
        }

        let lastIndex = lines.count - 1
        amount = lines[lastIndex].replacingOccurrences(of: " บาท", with: "")
            .replacingOccurrences(of: ",", with: "")
        refId = lines[lastIndex - 1]
        
        return [
            "bank":     bank,
            "date":     date,
            "sender":   sender,
            "receiver": receiver,
            "amount":   amount,
            "refId":    refId
        ]
    }
    
    static private func extractMake(from text: String) -> [String: String] {
        let bank     = Bank.MAKE.rawValue
        var date     = "-"
        var sender   = "-"
        var receiver = "-"
        var amount   = "-"
        var refId    = "-"
        
        // Precompile the two regexes we need:
        let dateRegex = try! NSRegularExpression(
          pattern: #"(\d{1,2}) (ม\.?ค\.?|ก\.?พ\.?|มี\.?ค\.?|เม\.?ย\.?|พ\.?ค\.?|มิ\.?ย\.?|ก\.?ค\.?|ส\.?ค\.?|ก\.?ย\.?|ต\.?ค\.?|พ\.?ย\.?|ธ\.?ค\.?) (\d{2,4}) (\d{2}:\d{2})"#,
          options: []
        )
        
        let replacedText = text.replacingOccurrences(of: "จ่ายละจิง\n", with: "")
            .replacingOccurrences(of: "\nPrompt\nPay", with: "\nPrompt Pay").replacingOccurrences(of: "\n0550\n", with: "\n")
        let lines = replacedText.components(separatedBy: "\n")
        
        // 2. Date & Time from line 1
        if lines.count > 1 {
                let dateTimeLine = lines[1]
                let range = NSRange(dateTimeLine.startIndex..<dateTimeLine.endIndex, in: dateTimeLine)
                if let match = dateRegex.firstMatch(in: dateTimeLine, options: [], range: range) {
                    let day = String(dateTimeLine[Range(match.range(at: 1), in: dateTimeLine)!])
                    let month = String(dateTimeLine[Range(match.range(at: 2), in: dateTimeLine)!])
                    let year = String(dateTimeLine[Range(match.range(at: 3), in: dateTimeLine)!])
                    date = "\(day) \(month) \(year)"
                }
            }
        
        // 3. Sender
        if lines.count > 5 {
            sender = lines[5]
        }
        
        if lines.count > 8 {
            if lines[8].contains("Prompt Pay") {
                receiver = lines[9]
            }
            else {
                receiver = lines[8]
            }
        }
        
        if lines.count > 10 {
            if lines[10].contains("จำนวน") {
                amount = lines[11].replacingOccurrences(of: " บาท", with: "")
                    .replacingOccurrences(of: ",", with: "")
                if lines[14].hasPrefix("เลขที่รายการ: "){
                    refId = lines[14].replacingOccurrences(of: "เลขที่รายการ: ", with: "")
                }
            } else {
                amount = lines[12].replacingOccurrences(of: " บาท", with: "")
                    .replacingOccurrences(of: ",", with: "")
                if lines[15].hasPrefix("เลขที่รายการ: "){
                    refId = lines[15].replacingOccurrences(of: "เลขที่รายการ: ", with: "")
                }
            }
        }
        
        return [
            "bank":     bank,
            "date":     date,
            "sender":   sender,
            "receiver": receiver,
            "amount":   amount,
            "refId":    refId
        ]
    }
    
    static private func extractKtb(from text: String) -> [String: String] {
        let bank     = Bank.KTB.rawValue
        var date     = "-"
        var sender   = "-"
        var receiver = "-"
        var amount   = "-"
        var refId    = "-"
        
        let replacedText = text.replacingOccurrences(of: "\nรหัสอ้างอิง ", with: "\n").replacingOccurrences(of: "\nรหัสอ้างอิง", with: "").replacingOccurrences(of: "\n0.00 บาท", with: "").replacingOccurrences(of: "\nค่าธรรมเนียม", with: "").replacingOccurrences(of: "\nวันที่ทำรายการ", with: "").replacingOccurrences(of: "\nจำนวนเงิน", with: "").replacingOccurrences(of: "\nไปยัง", with: "").replacingOccurrences(of: "\nจาก", with: "").replacingOccurrences(of: "\ne", with: "").replacingOccurrences(of: "\n•••", with: "")
        let lines = replacedText.components(separatedBy: "\n")
        
        let dateRegex = try! NSRegularExpression(
          pattern: #"(\d{1,2}) (ม\.?ค\.?|ก\.?พ\.?|มี\.?ค\.?|เม\.?ย\.?|พ\.?ค\.?|มิ\.?ย\.?|ก\.?ค\.?|ส\.?ค\.?|ก\.?ย\.?|ต\.?ค\.?|พ\.?ย\.?|ธ\.?ค\.?) (\d{2,4}) - (\d{2}:\d{2})"#,
          options: []
        )
        
        for line in 0..<lines.count {
            if let m = dateRegex.firstMatch(in: lines[line], options: [], range: NSRange(lines[line].startIndex..., in: lines[line])) {
                let day     = String(lines[line][Range(m.range(at: 1), in: lines[line])!])
                let month   = String(lines[line][Range(m.range(at: 2), in: lines[line])!])
                let year    = String(lines[line][Range(m.range(at: 3), in: lines[line])!])

                // Reformat date if needed
                date = "\(day) \(month) \(year)"
                let amountText = lines[line - 1].replacingOccurrences(of: " บาท", with: "")
                    .replacingOccurrences(of: ",", with: "")
                
                // Check if amount string can be converted to Double
                if let _ = Double(amountText) {
                    amount = amountText
                }
                
                continue
            }
        }
        
        if lines.count > 3 {
            refId = lines[3]
        }
        
        if lines.count > 4 {
            sender = lines[4]
        }
        
        if lines.count > 7 {
            receiver = lines[7]
        }
        
        return [
            "bank":     bank,
            "date":     date,
            "sender":   sender,
            "receiver": receiver,
            "amount":   amount,
            "refId":    refId
        ]
    }
    
    static func extractTransactionData(from text: String) -> [String: String] {
//        print("[DEBUG] OCR Raw Text:\n\(text)\n— End OCR Raw Text —")

        // Default values
        var bank     = "Unknown"
        var date     = "-"
        var sender   = "-"
        var receiver = "-"
        var amount   = "-"
        var refId    = "-"
        
        for (i, l) in text.split(separator: "\n").enumerated(){
                    print("[\(i)] \(l)")}

        // 1. Bank detection (simple keyword match)
        if text.contains("Krungthai") {
            return extractKtb(from: text)
        } else if text.contains("K+\n") {
            return extractKbank(from: text)
        } else if text.contains("SCB") {
            return extractScb(from: text)
        } else if text.contains("maKe") || text.contains("make") || text.contains("by KBank") {
            return extractMake(from: text)
        }
        
        let textReplaceedPromptPay = text.replacingOccurrences(of: "\nPrompt\nPay", with: "")

        // 2. Split into trimmed lines
        let lines = textReplaceedPromptPay
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // 3. Patterns for date/time
        let patterns = try! [
            NSRegularExpression(pattern: "(\\d{1,2} [ก-ธ]+\\.? ?\\d{2,4})[ -]+(\\d{2}:\\d{2})", options: []),
            NSRegularExpression(pattern: "(\\d{1,2} [ก-ธ]+\\.? ?\\d{2,4}) (\\d{2}:\\d{2}) น\\.", options: [])
        ]

        for line in lines {
            // A) Date & Time
            if date == "-" {
                for pattern in patterns {
                    let nsString = line as NSString
                    if let match = pattern.firstMatch(in: line, range: NSRange(location: 0, length: nsString.length)) {
                        let dateRange = match.range(at: 1)
                        date = nsString.substring(with: dateRange)
                        break
                    }
                }
            }

            // B) Sender (after "จาก", or line starting with honorific)
            if sender == "-" {
                if line == "จาก", let idx = lines.firstIndex(of: line), idx+1 < lines.count {
                    sender = lines[idx+1]
                } else if line.hasPrefix("นาย") || line.hasPrefix("น.ส.") {
                    sender = line
                }
            }

            // C) Receiver (after "ไปยัง", "ไป", or PromptPay/SHOP lines)
            if receiver == "-" {
                if line == "ไปยัง", let idx = lines.firstIndex(of: line), idx+1 < lines.count {
                    receiver = lines[idx+1]
                } else if line.hasPrefix("ไปยัง") {
                    receiver = line.replacingOccurrences(of: "ไปยัง", with: "").trimmingCharacters(in: .whitespaces)
                } else if line == "ไป", let idx = lines.firstIndex(of: line), idx+1 < lines.count {
                    receiver = lines[idx+1]
                } else if line.contains("Prompt") || line.contains("SHOP") {
                    // Next non-empty line after this
                    if let idx = lines.firstIndex(of: line),
                       idx+1 < lines.count {
                        receiver = lines[idx+1]
                    }
                }
            }

            // D) Amount (after "จำนวนเงิน", "จำนวน:", "จำนวน")
            if amount == "-" {
                if line.contains("จำนวนเงิน"), let idx = lines.firstIndex(of: line), idx+1 < lines.count {
                    let found = lines[idx+1]
                    if (found.firstMatch(of: /([\d,]+(?:\.\d{1,2})?)/) != nil) {
                        found.replacingOccurrences(of: ",", with: "")
                    }
                    amount = found
                } else if line.lowercased().hasPrefix("จำนวน"), let idx = lines.firstIndex(of: line), idx+1 < lines.count {
                    let found = lines[idx+1]
                    if (found.firstMatch(of: /([\d,]+(?:\.\d{1,2})?)/) != nil) {
                        found.replacingOccurrences(of: ",", with: "")
                    }
                    amount = found
                } else {
                    // Fallback: look for digits right in this line
                    if let m = line.firstMatch(of: /([\d,]+(?:\.\d{1,2})?)/) {
                        let found = String(m.1)
                        // ignore lines like "ค่าธรรมเนียม 0.00"
                        if !line.contains("ค่าธรรมเนียม") {
                            amount = found
                        }
                    }
                }
            }
        }
        
        return [
            "bank":     bank,
            "date":     date,
            "sender":   sender,
            "receiver": receiver,
            "amount":   amount,
            "refId":    refId
        ]
    }
}
