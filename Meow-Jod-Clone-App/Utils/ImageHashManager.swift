import Foundation
import CryptoKit
import UIKit
import Photos

class ImageHashManager {
    static let shared = ImageHashManager()
    private let processedHashesKey = "processed_slip_hashes"
    private let processedAssetIdsKey = "processed_asset_ids"
    
    // Queue for thread-safe access
    private let queue = DispatchQueue(label: "com.meowjod.imagehashmanager", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Image Hashing (Legacy / Non-Asset)
    func computeHash(for image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func isProcessed(image: UIImage) -> Bool {
        guard let hash = computeHash(for: image) else { return false }
        return queue.sync {
            let processedHashes = getProcessedHashes()
            return processedHashes.contains(hash)
        }
    }
    
    func markAsProcessed(image: UIImage) {
        guard let hash = computeHash(for: image) else { return }
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            var processedHashes = self.getProcessedHashes()
            processedHashes.insert(hash)
            self.saveProcessedHashes(processedHashes)
        }
    }
    
    // MARK: - PHAsset ID Tracking
    func isProcessed(asset: PHAsset) -> Bool {
        return queue.sync {
            let processedIds = getProcessedAssetIds()
            return processedIds.contains(asset.localIdentifier)
        }
    }
    
    func markAsProcessed(asset: PHAsset) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            var processedIds = self.getProcessedAssetIds()
            processedIds.insert(asset.localIdentifier)
            self.saveProcessedAssetIds(processedIds)
        }
    }
    
    // MARK: - Storage Helpers
    // These helpers are now called from within the queue blocks, so they don't need their own locking if private
    private func getProcessedHashes() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: processedHashesKey) as? [String] else {
            return []
        }
        return Set(array)
    }
    
    private func saveProcessedHashes(_ hashes: Set<String>) {
        UserDefaults.standard.set(Array(hashes), forKey: processedHashesKey)
    }
    
    private func getProcessedAssetIds() -> Set<String> {
        guard let array = UserDefaults.standard.array(forKey: processedAssetIdsKey) as? [String] else {
            return []
        }
        return Set(array)
    }
    
    private func saveProcessedAssetIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: processedAssetIdsKey)
    }
    
    // For debugging/dev: clear history
    func clearHistory() {
        queue.async(flags: .barrier) { [weak self] in
            UserDefaults.standard.removeObject(forKey: self?.processedHashesKey ?? "")
            UserDefaults.standard.removeObject(forKey: self?.processedAssetIdsKey ?? "")
        }
    }
}
