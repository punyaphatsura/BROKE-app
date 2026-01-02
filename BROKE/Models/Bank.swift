//
//  Bank.swift
//  BROKE
//
//  Created by Assistant on 30/11/2568 BE.
//

import Foundation
import SwiftUI

enum Bank: String, CaseIterable, Codable, Identifiable {
    case kbank = "KBank"
    case scb = "SCB"
    case ktb = "Krungthai"
    case bbl = "Bangkok Bank"
    case ttb = "TTB"
    case gsb = "GSB"
    case bay = "Krungsri"
    case cimb = "CIMB"
    case uob = "UOB"
    case tisco = "TISCO"
    case lhb = "LHB"
    case kk = "Kiatnakin"
    case tbank = "Thanachart"
    case make = "MAKE by KBank"
    case unknown = "Unknown"
    
    var id: String { rawValue }
    
    var iconName: String? {
        switch self {
        case .kbank: return "kbank_icon"
        case .scb: return "scb_icon"
        case .ktb: return "ktb_icon"
        case .bbl: return "bbl_icon"
        case .ttb: return "ttb_icon"
        case .gsb: return "gsb_icon"
        case .bay: return "bay_icon"
        case .make: return "make_icon"
        case .cimb: return "cimb_icon"
        case .uob: return "uob_icon"
        case .tisco: return "tisco_icon"
        case .lhb: return "lhb_icon"
        case .kk: return "kk_icon"
        case .tbank: return "tbank_icon"
        default: return nil
        }
    }
    
    static func from(string: String) -> Bank {
        let lowercased = string.lowercased()
        
        // Check for bank codes first
        switch string {
        case "004": return .kbank
        case "014": return .scb
        case "006": return .ktb
        case "002": return .bbl
        case "011": return .ttb
        case "030": return .gsb
        case "025": return .bay
        case "022": return .cimb
        case "024": return .uob
        case "067": return .tisco
        case "073": return .lhb
        case "069": return .kk
        case "065": return .tbank // Legacy Thanachart
        default: break
        }
        
        if lowercased.contains("kbank") || lowercased.contains("kasikorn") || lowercased.contains("กสิกร") {
            return .kbank
        } else if lowercased.contains("make") {
            return .make
        } else if lowercased.contains("scb") || lowercased.contains("siam commercial") || lowercased.contains("ไทยพาณิชย์") {
            return .scb
        } else if lowercased.contains("ktb") || lowercased.contains("krungthai") || lowercased.contains("กรุงไทย") {
            return .ktb
        } else if lowercased.contains("bbl") || lowercased.contains("bangkok") || lowercased.contains("กรุงเทพ") {
            return .bbl
        } else if lowercased.contains("ttb") || lowercased.contains("tmb") || lowercased.contains("thanachart") || lowercased.contains("ทหารไทย") {
            return .ttb
        } else if lowercased.contains("gsb") || lowercased.contains("government savings") || lowercased.contains("ออมสิน") {
            return .gsb
        } else if lowercased.contains("bay") || lowercased.contains("krungsri") || lowercased.contains("กรุงศรี") {
            return .bay
        }
        
        return .unknown
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
