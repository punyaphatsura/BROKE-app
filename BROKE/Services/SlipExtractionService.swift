//
//  SlipExtractionService.swift
//  BROKE
//
//  Created by Assistant on 30/11/2568 BE.
//

import FirebaseAILogic
import Foundation
import SwiftUI
import Vision

class SlipExtractionService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var showQuotaError = false

    static let quotaUpdatedNotification = Notification.Name("SlipOKQuotaUpdated")
    static let quotaUsedNotification = Notification.Name("SlipOKQuotaUsed")

    private let model: GenerativeModel

    init() {
        // Initialize the Gemini Developer API backend service
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())

        // Create a `GenerativeModel` instance with a model that supports your use case
        // Using gemini-2.5-flash as requested
        model = ai.generativeModel(modelName: "gemini-2.5-flash")
    }

    func processSlip(image: UIImage, useGeminiOnly: Bool = false, completion: @escaping (SlipData?) -> Void) {
        if useGeminiOnly {
            processSlipWithGemini(image: image, completion: completion)
            return
        }

        DispatchQueue.main.async {
            self.isProcessing = true
            self.lastError = nil
            self.showQuotaError = false
        }

        // Try to extract QR Code
        if let qrCode = extractQRCode(from: image) {
            processSlipWithSlipOK(qrCode: qrCode) { [weak self] slipData in
                if let slipData = slipData {
                    DispatchQueue.main.async {
                        self?.isProcessing = false
                        completion(slipData)
                    }
                } else {
                    // Fallback to Gemini if SlipOK fails
                    self?.processSlipWithGemini(image: image, completion: completion)
                }
            }
        } else {
            // No QR Code, use Gemini
            processSlipWithGemini(image: image, completion: completion)
        }
    }

    private func processSlipWithGemini(image: UIImage, completion: @escaping (SlipData?) -> Void) {
        guard let resizedImage = resizeImage(image, targetSize: CGSize(width: 1024, height: 1024)) else {
            DispatchQueue.main.async {
                self.lastError = "Failed to prepare image"
                completion(nil)
            }
            return
        }

        DispatchQueue.main.async {
            self.isProcessing = true
            self.lastError = nil
            self.showQuotaError = false
        }

        let prompt = """
        Analyze this bank transfer slip (Thai bank slip). Extract the following details and return ONLY a valid JSON object with no markdown formatting or other text.

        JSON Keys:
        - bank: The bank name. Return one of these exact strings: "KBank", "SCB", "Krungthai", "Bangkok Bank", "TTB", "GSB", "Krungsri", "CIMB", "UOB", "TISCO", "LHB", "Kiatnakin", "Thanachart", "MAKE by KBank".
        - date: The transaction date (preferably in DD/MM/YYYY format, convert Buddhist year to Gregorian if needed).
        - sender: The sender's name.
        - receiver: The receiver's name.
        - amount: The amount transferred (numbers only, no comma).
        - refId: The transaction reference ID.

        If a field is not found or unclear, set the value to "-".
        """

        Task {
            do {
                let response = try await model.generateContent(prompt, resizedImage)

                DispatchQueue.main.async {
                    self.isProcessing = false

                    guard let text = response.text else {
                        self.lastError = "No response text from Gemini"
                        completion(nil)
                        return
                    }

                    if let slipData = self.parseGeminiResponse(text) {
                        completion(slipData)
                    } else {
                        self.lastError = "Failed to parse Gemini response"
                        completion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    let errorMsg = error.localizedDescription

                    // Check for quota exceeded error
                    if errorMsg.contains("429") || errorMsg.contains("RESOURCE_EXHAUSTED") || errorMsg.contains("quota") {
                        self.showQuotaError = true
                        self.lastError = "Gemini API quota exceeded. Please try again later."
                    } else {
                        self.lastError = errorMsg
                    }

                    completion(nil)
                }
            }
        }
    }

    func checkSlipOKQuota() async throws -> Int {
        let urlString = "https://api.slipok.com/api/line/apikey/\(Secrets.slipOKBranch)/quota"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(Secrets.slipOKAuthorization, forHTTPHeaderField: "x-authorization")

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        let result = try decoder.decode(SlipOKQuotaResponse.self, from: data)

        if result.success, let quotaData = result.data {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.quotaUpdatedNotification, object: nil, userInfo: ["quota": quotaData.quota])
            }
            return quotaData.quota
        }

        throw URLError(.cannotParseResponse)
    }

    private func processSlipWithSlipOK(qrCode: String, completion: @escaping (SlipData?) -> Void) {
        let urlString = "https://api.slipok.com/api/line/apikey/\(Secrets.slipOKBranch)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Secrets.slipOKAuthorization, forHTTPHeaderField: "x-authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "data": qrCode,
            "log": false,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else {
                completion(nil)
                return
            }

            if let error = error {
                print("SlipOK Error: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                completion(nil)
                return
            }

            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(SlipOKResponse.self, from: data)

                if result.success, let data = result.data {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Self.quotaUsedNotification, object: nil)
                    }
                    let slipData = self.mapSlipOKToSlipData(data)
                    completion(slipData)
                } else {
                    completion(nil)
                }
            } catch {
                print("SlipOK Parse Error: \(error)")
                completion(nil)
            }
        }.resume()
    }

    private func extractQRCode(from image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let result = request.results?.first as? VNBarcodeObservation else { return nil }
            return result.payloadStringValue
        } catch {
            print("QR Extraction Error: \(error)")
            return nil
        }
    }

    private func mapSlipOKToSlipData(_ data: SlipOKData) -> SlipData {
        // Map Bank Code to Bank Name (relying on Bank.from to handle codes)
        let bankName = data.sendingBank ?? "Unknown"

        // Format Date
        var dateString = "-"
        if let transDate = data.transDate, let transTime = data.transTime {
            // transDate: 20251207 -> 2025-12-07
            if transDate.count == 8 {
                let y = String(transDate.prefix(4))
                let m = String(transDate.dropFirst(4).prefix(2))
                let d = String(transDate.suffix(2))
                dateString = "\(y)-\(m)-\(d) \(transTime)"
            } else {
                dateString = "\(transDate) \(transTime)"
            }
        }

        let senderName = data.sender?.displayName ?? data.sender?.name ?? "-"
        let receiverName = data.receiver?.displayName ?? data.receiver?.name ?? "-"

        let amountString = String(format: "%.2f", data.amount ?? 0.0)
        let refId = data.transRef ?? "-"

        let dict: [String: String] = [
            "bank": bankName,
            "date": dateString,
            "sender": senderName,
            "receiver": receiverName,
            "amount": amountString,
            "refId": refId,
        ]

        return SlipData(dictionary: dict)
    }

    private func parseGeminiResponse(_ text: String) -> SlipData? {
        // Clean up markdown code blocks if present
        let cleanText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleanText.data(using: .utf8) else { return nil }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                return SlipData(dictionary: json)
            }
        } catch {
            print("JSON Parse Error: \(error)")
            print("Raw text: \(text)")
        }

        return nil
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    // Helper for category suggestion
    func suggestCategory(for slipData: SlipData) -> ExpenseCategory {
        let receiver = slipData.receiver.lowercased()

        // Food related
        if receiver.contains("ร้านอาหาร") || receiver.contains("food") || receiver.contains("restaurant") ||
            receiver.contains("เซเว่น") || receiver.contains("7-eleven") || receiver.contains("แม็คโดนัลด์") ||
            receiver.contains("kfc") || receiver.contains("pizza") || receiver.contains("starbucks") ||
            receiver.contains("true coffee") || receiver.contains("amazon") || receiver.contains("foodpanda") ||
            receiver.contains("grab") || receiver.contains("lineman")
        {
            return .food
        }

        // Shopping
        if receiver.contains("mall") || receiver.contains("ห้าง") || receiver.contains("โลตัส") ||
            receiver.contains("big c") || receiver.contains("tops") || receiver.contains("makro") ||
            receiver.contains("lazada") || receiver.contains("shopee") || receiver.contains("central") ||
            receiver.contains("siam") || receiver.contains("terminal")
        {
            return .shopping
        }

        // Transport
        if receiver.contains("grab") || receiver.contains("taxi") || receiver.contains("แท็กซี่") ||
            receiver.contains("bts") || receiver.contains("mrt") || receiver.contains("รถไฟ") ||
            receiver.contains("ขสมก") || receiver.contains("shell") || receiver.contains("ptt") ||
            receiver.contains("bangchak") || receiver.contains("esso")
        {
            return .transport
        }

        // Entertainment
        if receiver.contains("cinema") || receiver.contains("โรงหนัง") || receiver.contains("netflix") ||
            receiver.contains("spotify") || receiver.contains("youtube") || receiver.contains("steam") ||
            receiver.contains("playstation") || receiver.contains("xbox") || receiver.contains("nintendo")
        {
            return .entertainment
        }

        // Health
        if receiver.contains("โรงพยาบาล") || receiver.contains("hospital") || receiver.contains("คลินิก") ||
            receiver.contains("clinic") || receiver.contains("pharmacy") || receiver.contains("ร้านยา") ||
            receiver.contains("boots") || receiver.contains("watson")
        {
            return .health
        }

        // Bills
        if receiver.contains("electricity") || receiver.contains("การไฟฟ้า") || receiver.contains("water") ||
            receiver.contains("ประปา") || receiver.contains("internet") || receiver.contains("true") ||
            receiver.contains("ais") || receiver.contains("dtac") || receiver.contains("nt") ||
            receiver.contains("กฟน") || receiver.contains("กฟภ")
        {
            return .bills
        }

        // Default
        return .others
    }
}

// MARK: - SlipOK Models

struct SlipOKResponse: Codable {
    let success: Bool
    let data: SlipOKData?
}

struct SlipOKData: Codable {
    let success: Bool?
    let message: String?
    let language: String?
    let transRef: String?
    let sendingBank: String?
    let receivingBank: String?
    let transDate: String?
    let transTime: String?
    let transTimestamp: String?
    let sender: SlipOKAccount?
    let receiver: SlipOKAccount?
    let amount: Double?
}

struct SlipOKAccount: Codable {
    let displayName: String?
    let name: String?
    let account: SlipOKAccountDetail?
}

struct SlipOKAccountDetail: Codable {
    let value: String?
}

struct SlipOKQuotaResponse: Codable {
    let success: Bool
    let data: SlipOKQuotaData?
}

struct SlipOKQuotaData: Codable {
    let quota: Int
}
