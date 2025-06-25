//
//  HomeView.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import SwiftUI
import PhotosUI
import Vision

struct ErrorTransaction: Identifiable {
    let id = UUID()
    let image: UIImage
    let text: String
}

struct HomeView: View {
    @EnvironmentObject var transactionStore: TransactionStore
    @EnvironmentObject var photoFetcher: PhotoFetcher
    @State private var showingAddTransaction = false
    
    @State private var isScanning = false
    @State private var transactionList: [Transaction] = []
    @State private var extractedTransaction: Transaction?
    @State private var showingTransactionPreview = false
    @State private var albumList: PHFetchResult<PHAssetCollection>? = nil
    @State private var totalImagesToProcess = 0
    @State private var processedImageCount = 0
    @State private var imageQueue: [UIImage] = []
    @State private var isProcessingOCR = false
    @State private var hasAttemptedAutoScan = false
    @State private var errorTransaction: [ErrorTransaction] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Summary Card
                // VStack(spacing: 20) {
                //     Text("Balance")
                //         .font(.headline)
                //     Text("$\(transactionStore.balance(), specifier: "%.2f")")
                //         .font(.largeTitle)
                //         .fontWeight(.bold)
                    
                //     HStack(spacing: 40) {
                //         VStack {
                //             Text("Income")
                //                 .font(.subheadline)
                //             Text("$\(transactionStore.totalIncome(), specifier: "%.2f")")
                //                 .foregroundColor(.green)
                //         }
                        
                //         VStack {
                //             Text("Expenses")
                //                 .font(.subheadline)
                //             Text("$\(transactionStore.totalExpense(), specifier: "%.2f")")
                //                 .foregroundColor(.red)
                //         }
                //     }
                // }
                // .padding()
                // .background(Color(.systemGray6))
                // .cornerRadius(12)
                // .padding()
                
                // Recent Transactions
                VStack(alignment: .leading) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(Array(transactionStore.transactions.prefix(5))) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                if isScanning {
                    VStack(spacing: 20) {
                        // Waiting/Processing Image
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .scaleEffect(isScanning ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isScanning)
                        
                        Text("Scanning Bank Slips...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Progress Bar
                        VStack(spacing: 8) {
                            ProgressView(value: Double(processedImageCount), total: Double(totalImagesToProcess))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                            
                            Text("Processed \(processedImageCount) of \(totalImagesToProcess) images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                else {
                    if !transactionList.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Extracted Transactions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Text("Successfully extracted \(transactionList.count) transactions from \(photoFetcher.images.count) images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            scannedResultList
                        }
                    }
                    if (!errorTransaction.isEmpty) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Error Transactions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Text("Error extracted \(errorTransaction.count) transactions from \(photoFetcher.images.count) images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            ScrollView{
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(errorTransaction) { errorItem in
                                        Image(uiImage: errorItem.image)
                                            .resizable()
                                            .frame(width: 150, height: 150)
                                            .cornerRadius(8)
                                            .shadow(radius: 2)
                                        Text(errorItem.text)
                                    }
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Bank Slip Images")
                        .font(.headline)
                        .padding(.horizontal)

                    if photoFetcher.images.isEmpty {
                        Text("No images found.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Found \(photoFetcher.images.count) images")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photoFetcher.images, id: \.self) { image in
                                        Image(uiImage: image)
                                            .resizable()
                                            .frame(width: 150, height: 150)
                                            .cornerRadius(8)
                                            .shadow(radius: 2)
                                    }
                                }.padding(.horizontal)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("[DEBUG] Manual scan triggered with \(photoFetcher.images.count) images")
                        hasAttemptedAutoScan = false
                        processImages()
                    }) {
                        Image(systemName: "doc.text.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .onReceive(photoFetcher.$isLoadingComplete) { isComplete in
                if isComplete && !isScanning && transactionList.isEmpty {
                     processImages()
                }
            }
        }
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
    
    private func processImages() {
        guard !photoFetcher.images.isEmpty else {
            return
        }
        
        print("🔍 Processing \(photoFetcher.images.count) images for OCR")
        transactionList.removeAll()
        totalImagesToProcess = photoFetcher.images.count
        processedImageCount = 0
        isScanning = true
        imageQueue.removeAll()
        isProcessingOCR = false
        
        for (index, image) in photoFetcher.images.enumerated() {
            DispatchQueue.main.async {
                self.imageQueue.append(image)
                self.startNextOCRIfNeeded()
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
                print(transactionData)
                if let refId = transactionData["refId"],
                   let amountString = transactionData["amount"],
                   let bankRaw = transactionData["bank"],
                   let dateString = transactionData["date"],
                   let parsedDate = parseThaiDate(dateString),
                   let receiver = transactionData["receiver"],
                   let sender = transactionData["sender"],
                   let amount = Double(amountString.replacingOccurrences(of: ",", with: "")),
                   let bank = Bank(rawValue: bankRaw)
                {
                    print("✅ Extracted transaction: \(refId) - \(amount) from \(bank.rawValue)")
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
                } else {
                    print("❌ Failed to extract transaction from image")
                    self.errorTransaction.append(ErrorTransaction(image: image, text: combinedText))
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
        if processedImageCount >= totalImagesToProcess {
            isScanning = false
            print("🎯 Finished processing. Extracted \(transactionList.count) transactions from \(totalImagesToProcess) images")
        }
    }
}
