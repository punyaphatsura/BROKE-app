//
//  SlipScannerViewModel.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 20/4/2568 BE.
//

import Foundation
import SwiftUI
import Photos

class SlipScannerViewModel: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var processedSlipData: SlipData?
    @Published var errorMessage: String?
    @Published var selectedImage: UIImage?
    
    // OCR Settings
    @Published var enableSlipValidation = true
    
    private let slipExtractor = SlipExtractionService()
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    override init() {
        super.init()
    }
    
    // MARK: - Image Processing
    func processImage(_ image: UIImage, asset: PHAsset? = nil) {
        // Deduplication Check
        if let asset = asset, ImageHashManager.shared.isProcessed(asset: asset) {
            print("Duplicate asset detected. Skipping Gemini call.")
            self.errorMessage = "Image already processed."
            return
        }
        
        if asset == nil && ImageHashManager.shared.isProcessed(image: image) {
             print("Duplicate image hash detected. Skipping Gemini call.")
             self.errorMessage = "Image already processed."
             return
        }
        
        selectedImage = image
        isProcessing = true
        errorMessage = nil
        processedSlipData = nil
        
        slipExtractor.processSlip(image: image) { [weak self] slipData in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if var slipData = slipData {
                    if let asset = asset {
                        slipData.imagePath = asset.localIdentifier
                    }
                    
                    self?.processedSlipData = slipData
                    
                    if let asset = asset {
                        ImageHashManager.shared.markAsProcessed(asset: asset)
                    }
                    ImageHashManager.shared.markAsProcessed(image: image)
                    
                    if self?.enableSlipValidation == true {
                        self?.validateSlipData(slipData)
                    }
                } else {
                    self?.errorMessage = self?.slipExtractor.lastError ?? "Failed to process slip"
                }
            }
        }
    }
    
    // MARK: - Batch Processing
    func processBatch(assets: [PHAsset], completion: @escaping (Int) -> Void) {
        // Request background execution time
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "BatchSlipProcessing") {
            // End the task if time expires
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }
        
        executeBatchProcessing(assets: assets, retryCount: 0, totalProcessed: 0) { count in
            completion(count)
            
            // End background task when finished
            if self.backgroundTaskID != .invalid {
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = .invalid
            }
        }
    }
    
    private func executeBatchProcessing(assets: [PHAsset], retryCount: Int, totalProcessed: Int, completion: @escaping (Int) -> Void) {
        let unprocessedAssets = assets.filter { !ImageHashManager.shared.isProcessed(asset: $0) }
        
        guard !unprocessedAssets.isEmpty else {
            DispatchQueue.main.async {
                self.isProcessing = false
                completion(totalProcessed)
            }
            return
        }
        
        // Only show processing indicator on first attempt or if we are actively working
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        let group = DispatchGroup()
        // Limit concurrent requests to 1 to stay within Free Tier limits (approx 15 RPM)
        let semaphore = DispatchSemaphore(value: 2)
        var currentBatchProcessed = 0
        var shouldStopProcessing = false
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            for asset in unprocessedAssets {
                // Check if we should stop early (due to quota error)
                if shouldStopProcessing { break }
                
                group.enter()
                semaphore.wait()
                
                // Add delay to pace requests (15 RPM = 1 request every 4s)
                // We sleep for 4 seconds to be safe.
                Thread.sleep(forTimeInterval: 4.0)
                
                // Fetch image
                let manager = PHCachingImageManager.default()
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isSynchronous = false
                options.isNetworkAccessAllowed = true
                
                manager.requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024), contentMode: .aspectFit, options: options) { [weak self] image, _ in
                    guard let self = self, let image = image else {
                        semaphore.signal()
                        group.leave()
                        return
                    }
                    
                    self.slipExtractor.processSlip(image: image) { [weak self] slipData in
                        DispatchQueue.main.async {
                            guard let self = self else {
                                semaphore.signal()
                                group.leave()
                                return
                            }
                            
                            if var slipData = slipData {
                                slipData.imagePath = asset.localIdentifier
                                
                                // Updating processedSlipData triggers HomeView to save it
                                self.processedSlipData = slipData
                                
                                ImageHashManager.shared.markAsProcessed(asset: asset)
                                ImageHashManager.shared.markAsProcessed(image: image)
                                currentBatchProcessed += 1
                            } else {
                                print("Batch processing failed for an image: \(self.slipExtractor.lastError ?? "Unknown error")")
                                
                                // Check if the failure was due to Quota Limit
                                if self.slipExtractor.showQuotaError {
                                    print("Quota limit reached. Stopping batch processing.")
                                    shouldStopProcessing = true
                                    self.errorMessage = "Quota limit reached. Stopping batch."
                                }
                            }
                            
                            semaphore.signal()
                            group.leave()
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                let newTotal = totalProcessed + currentBatchProcessed
                let remainingUnprocessed = assets.filter { !ImageHashManager.shared.isProcessed(asset: $0) }
                
                if !remainingUnprocessed.isEmpty && retryCount < 3 {
                    print("Batch partially failed. Retrying... (\(retryCount + 1)/3)")
                    print("Remaining unprocessed: \(remainingUnprocessed.count)")
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                        self.executeBatchProcessing(assets: assets, retryCount: retryCount + 1, totalProcessed: newTotal, completion: completion)
                    }
                } else {
                    self.isProcessing = false
                    if !remainingUnprocessed.isEmpty {
                        print("Batch finished with \(remainingUnprocessed.count) failed items after retries.")
                    }
                    completion(newTotal)
                }
            }
        }
    }
    
    private func validateSlipData(_ slipData: SlipData) {
        var errors: [String] = []
        
        if slipData.bank == "Unknown" {
            errors.append(NSLocalizedString("error.bank_not_detected", comment: "Bank not detected"))
        }
        
        if slipData.parsedAmount == nil {
            errors.append(NSLocalizedString("error.amount_not_detected", comment: "Amount not detected"))
        }
        
        if slipData.parsedDate == nil {
            errors.append(NSLocalizedString("error.date_not_detected", comment: "Date not detected"))
        }
        
        if slipData.sender == "-" {
            errors.append(NSLocalizedString("error.sender_not_detected", comment: "Sender not detected"))
        }
        
        if slipData.receiver == "-" {
            errors.append(NSLocalizedString("error.receiver_not_detected", comment: "Receiver not detected"))
        }
        
        if !errors.isEmpty {
            errorMessage = errors.joined(separator: "\n")
        }
    }
    
    // MARK: - Category Suggestion
    func suggestCategory(for slipData: SlipData) -> ExpenseCategory {
        return slipExtractor.suggestCategory(for: slipData)
    }
    
    // MARK: - Reset
    func resetProcessing() {
        isProcessing = false
        processedSlipData = nil
        errorMessage = nil
        selectedImage = nil
    }
}
