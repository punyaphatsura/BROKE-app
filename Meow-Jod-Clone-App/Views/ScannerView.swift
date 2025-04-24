//
//  ScannerView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI
import PhotosUI
import Vision

struct ScannerView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isScanning = false
    @State private var recognizedText: [[String: String]] = []
    @State private var extractedTransaction: Transaction?
    @State private var showingTransactionPreview = false
    @State private var albumList: PHFetchResult<PHAssetCollection>? = nil
    @State private var totalImagesToProcess = 0
    @State private var processedImageCount = 0
    @State private var imageQueue: [UIImage] = []
    @State private var isProcessingOCR = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isScanning {
                    scanningProgressView
                } else {
                    mainScannerView
                }
            }
            .navigationTitle("Scan Bank Slips")
            .sheet(isPresented: $showingTransactionPreview) {
                if let transaction = extractedTransaction {
                    TransactionPreviewView(transaction: transaction) { confirmedTransaction in
                        transactionStore.addTransaction(confirmedTransaction)
                        extractedTransaction = nil
                        recognizedText.removeAll()
                    }
                }
            }
            .onAppear {
                fetchAlbums()
            }
        }
    }
    
    private var scanningProgressView: some View {
        VStack(spacing: 20) {
            Text("Scanning Bank Slips...")
                .font(.headline)
            ProgressView(value: Double(processedImageCount), total: Double(totalImagesToProcess))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding()
            Text("Processed \(processedImageCount) of \(totalImagesToProcess) images")
                .font(.subheadline)
        }
        .padding()
    }
    
    private var mainScannerView: some View {
        VStack(spacing: 20) {
            Text("Scan Bank Slips")
                .font(.headline)
            Text("Select images from your gallery to scan bank slips and extract transaction data.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            PhotosPicker(selection: $selectedItems, matching: .images) {
                Label("Select Bank Slips", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .onChange(of: selectedItems) { _, newItems in
                if !newItems.isEmpty {
                    processImages(newItems)
                }
            }
            
            if !recognizedText.isEmpty {
                scannedResultList
            }
        }
        .padding()
    }
    
    private var scannedResultList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(recognizedText, id: \.self) { textItem in
                    VStack(alignment: .leading, spacing: 4) {
                        if let refId = textItem["refId"] {
                            Text("Reference ID: \(refId)").font(.headline)
                        }
                        if let bank = textItem["bank"] {
                            Text("Bank: \(bank)").font(.headline)
                        }
                        if let date = textItem["date"], let time = textItem["time"] {
                            Text("Date: \(date) \(time)")
                        }
                        if let sender = textItem["sender"] {
                            Text("Sender: \(sender)")
                        }
                        if let receiver = textItem["receiver"] {
                            Text("Receiver: \(receiver)")
                        }
                        if let amount = textItem["amount"] {
                            Text("Amount: \(amount)")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onLongPressGesture {
                        UIPasteboard.general.string = textItem.description
                    }
                }
            }
            .padding()
        }
    }
    
    private func fetchAlbums() {
        albumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        if let albumList = albumList {
            print("[DEBUG] Found \(albumList.count) albums")
            albumList.enumerateObjects { collection, _, _ in
                print("- \(collection.localizedTitle ?? "Unknown")")
            }
        } else {
            print("[DEBUG] No albums fetched")
        }
    }
    
    private func processImages(_ items: [PhotosPickerItem]) {
        recognizedText.removeAll()
        totalImagesToProcess = items.count
        processedImageCount = 0
        isScanning = true
        imageQueue.removeAll()
        isProcessingOCR = false
        
        for item in items {
            item.loadTransferable(type: Data.self) { result in
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.imageQueue.append(image)
                            self.startNextOCRIfNeeded()
                        }
                    } else {
                        incrementProcessedImageCount()
                    }
                case .failure(let error):
                    print("Error loading image: \(error)")
                    incrementProcessedImageCount()
                }
            }
        }
    }

    
    private func startNextOCRIfNeeded() {
        guard !isProcessingOCR else { return }
        guard !imageQueue.isEmpty else { return }
        
        isProcessingOCR = true
        let image = imageQueue.removeFirst()
        recognizeTextSequentially(image: image)
    }

    private func recognizeTextSequentially(image: UIImage) {
        print("Recognizing next image...")
        guard let cgImage = image.cgImage else {
            incrementProcessedImageCount()
            isProcessingOCR = false
            startNextOCRIfNeeded()
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text recognition error: \(error)")
                self.incrementProcessedImageCount()
                self.isProcessingOCR = false
                self.startNextOCRIfNeeded()
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.incrementProcessedImageCount()
                self.isProcessingOCR = false
                self.startNextOCRIfNeeded()
                return
            }
            
            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            DispatchQueue.main.async {
                let combinedText = recognizedStrings.joined(separator: "\n")
                let transactionData = extractTransactionData(from: combinedText)
                self.recognizedText.append(transactionData)
                self.incrementProcessedImageCount()
                self.isProcessingOCR = false
                self.startNextOCRIfNeeded()
            }
        }
        
        request.recognitionLanguages = ["th-TH", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                print("Unable to perform text recognition: \(error)")
                DispatchQueue.main.async {
                    self.incrementProcessedImageCount()
                    self.isProcessingOCR = false
                    self.startNextOCRIfNeeded()
                }
            }
        }
    }

    
    private func incrementProcessedImageCount() {
        processedImageCount += 1
        print("[DEBUG] Processed \(processedImageCount)/\(totalImagesToProcess)")
        if processedImageCount >= totalImagesToProcess {
            isScanning = false
            print("[DEBUG] All images processed ✅")
        }
    }
    
    private func extractScb(from text: String) -> [String: String] {
        let bank = "SCB"
        var date     = "-"
        var time     = "-"
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
                let timeStr = String(line[Range(m.range(at: 4), in: line)!])

                // Reformat date if needed
                date = "\(day) \(month) \(year)"
                time = timeStr
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
                    // receiver is two lines after that (skip the sender’s account line)
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

        return [
            "bank":     bank,
            "date":     date,
            "time":     time,
            "sender":   sender,
            "receiver": receiver,
            "amount":   amount,
            "refId":    refId
        ]
    }
    
    private func extractTransactionData(from text: String) -> [String: String] {
//        print("[DEBUG] OCR Raw Text:\n\(text)\n— End OCR Raw Text —")

        // Default values
        var bank     = "Unknown"
        var date     = "-"
        var time     = "-"
        var sender   = "-"
        var receiver = "-"
        var amount   = "-"
        var refId = "-"

        // 1. Bank detection (simple keyword match)
        if text.contains("กรุงไทย") {
            bank = "Krungthai"
        } else if text.contains("K+") {
            bank = "KBank"
        } else if text.contains("SCB") {
             return extractScb(from: text)
        } else if text.contains("maKe") {
            bank = "maKe by KBank"
        }
        
        let textReplaceedPromptPay = text.replacingOccurrences(of: "\nPrompt\nPay\n", with: "\nPrompt Pay: ")

        // 2. Split into trimmed lines
        let lines = textReplaceedPromptPay
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // 3. Patterns for date/time
        let patterns = [/(\d{1,2} [ก-ธ]+\.? ?\d{2,4})[ -]+(\d{2}:\d{2})/, /(\d{1,2} [ก-ธ]+\.? ?\d{2,4}) (\d{2}:\d{2}) น\./]
        
        print("\nBank: \(bank)")
        for i in 0..<lines.count {
            print("[\(i)] \(lines[i])")
        }
        print()

        for line in lines {
            // A) Date & Time
            if date == "-" || time == "-" {
                for pattern in patterns {
                    if let m = line.firstMatch(of: pattern) {
                        date = String(m.1)
                        time = String(m.2)
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
            "time":     time,
            "sender":   sender,
            "receiver": receiver,
            "amount":   amount,
            "refId":    refId
        ]
    }

}
