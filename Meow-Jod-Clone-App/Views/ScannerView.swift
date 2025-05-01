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
    @State private var transactionList: [Transaction] = []
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
                        transactionList.removeAll()
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
            
            if !transactionList.isEmpty {
                scannedResultList
            }
        }
        .padding()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "dd MMM yyyy"
        let calendar = Calendar(identifier: .buddhist)
        formatter.calendar = calendar
        let thaiDate = formatter.string(from: date)
        
        // Convert Buddhist year to AD year
        let components = thaiDate.components(separatedBy: " ")
        if components.count == 3,
           let buddhistYear = Int(components[2]) {
            let adYear = buddhistYear - 543
            return "\(components[0]) \(components[1]) \(adYear)"
        }
        return thaiDate
    }

    
    private var scannedResultList: some View {
        ScrollView {
            Text("Transaction Number: \(transactionList.count)")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(transactionList) { t in
                    VStack(alignment: .leading, spacing: 4) {
                        if let refId = t.refId {
                            Text("Reference ID: \(refId)").font(.headline)
                        }
                        
                        if let bank = t.bank {
                            Text("Bank: \(bank.rawValue)").font(.headline)
                        }
                        
                        Text("Date: \(formattedDate(t.date))")

                        Text("Type: \(t.type == .expense ? "Expense" : "Income")")
                        Text("Amount: \(String(format: "%.2f", t.amount))")
                        
                        if let sender = t.sender {
                            Text("Sender: \(sender)")
                        }
                        
                        if let receiver = t.receiver {
                            Text("Receiver: \(receiver)")
                        }
                        
                        if let category = t.categoryId {
                            Text("Category: \(category.rawValue)")
                        }
                        
                        if let imagePath = t.imagePath,
                           let uiImage = UIImage(contentsOfFile: imagePath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onLongPressGesture {
                        UIPasteboard.general.string = t.description
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
        transactionList.removeAll()
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
    
    func parseThaiDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        
        // Clean up the string and extract components
        let clean = dateString.trimmingCharacters(in: .whitespaces)
        let components = clean.components(separatedBy: .whitespaces)
        
        guard components.count >= 3 else { return nil }
        
        // Convert 2-digit year to 4-digit year (25xx)
        if let yearStr = components.last, let twoDigitYear = Int(yearStr) {
            let fullYear = 2500 + twoDigitYear // Convert Buddhist year to AD
            
            // Reconstruct date string with 4-digit year
            let dateWithFullYear = "\(components[0]) \(components[1]) \(fullYear)"
            
            formatter.dateFormat = "d MMM yyyy"
            return formatter.date(from: dateWithFullYear)
        }
        
        return nil
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
                var imagePath = ""
                if let data = image.jpegData(compressionQuality: 1.0) {
                    let filename = UUID().uuidString + ".jpg"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                    do {
                        try data.write(to: tempURL)
                        imagePath = tempURL.path()
                    } catch {
                        print("Error saving image:", error)
                    }
                }
                let combinedText = recognizedStrings.joined(separator: "\n")
                let transactionData = ExtractFromSlip.extractTransactionData(from: combinedText)
                if let refId = transactionData["refId"],
                   let amountString = transactionData["amount"],
                   let amount = Double(amountString.replacingOccurrences(of: ",", with: "")),
                   let bankRaw = transactionData["bank"],
                   let bank = Bank(rawValue: bankRaw),
                   let dateString = transactionData["date"],
                   let parsedDate = parseThaiDate(dateString),
                   let receiver = transactionData["receiver"],
                   let sender = transactionData["sender"]
                {
                    let transaction = Transaction(
                        refId: refId,
                        amount: amount,
                        description: "",
                        date: parsedDate,
                        sender: sender,
                        receiver: receiver,
                        type: .expense,
                        source: .scan,
                        bank: bank,
                        imagePath: imagePath
                    )

                    self.transactionList.append(transaction)
                }
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
    
    

}
