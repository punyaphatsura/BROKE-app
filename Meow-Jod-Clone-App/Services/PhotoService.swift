//
//  PhotoService.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 12/5/2568 BE.
//

import Foundation
import SwiftUI
import Photos

class PhotoService: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var isLoadingComplete = false
    
    private let imageManager = PHCachingImageManager()
    private let albumNames = ["SCB Easy", "MAKE by KBank", "K PLUS", "Krungthai NEXT"]

    init() {
        requestPermissionAndFetch()
    }

    private func requestPermissionAndFetch() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized || status == .limited {
                self.fetchPhotos()
            }
        }
    }

    func fetchPhotos() {
        var fetchedAssets: [PHAsset] = []
        
        // Define the cutoff date: Dec 1, 2025
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 11
        dateComponents.day = 22
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(from: dateComponents) else { return }
        
        for albumName in albumNames {
            // 1. Fetch the Album Collection
            let collectionOptions = PHFetchOptions()
            collectionOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: collectionOptions)
            
            guard let album = collections.firstObject else { 
                continue 
            }
            
            // 2. Fetch Assets inside the Album with Date Filter
            let assetOptions = PHFetchOptions()
            assetOptions.predicate = NSPredicate(format: "creationDate >= %@", cutoffDate as NSDate)
            // Optional: Sort by creation date (newest first)
            assetOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let assets = PHAsset.fetchAssets(in: album, options: assetOptions)
            print("Found \(assets.count) assets in \(albumName) after \(cutoffDate)")

            assets.enumerateObjects { asset, _, _ in
                fetchedAssets.append(asset)
            }
        }
        
        DispatchQueue.main.async {
            // Since we might have duplicates if an image is in multiple albums (unlikely for specific bank apps but possible),
            // or just to be clean, we replace the array.
            // Also sort the combined result if needed, but here we just append.
            // Let's sort the final list by date descending just in case.
            self.assets = fetchedAssets.sorted {
                ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
            }
            self.isLoadingComplete = true
        }
    }
    
    func fetchImage(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options) { image, _ in
            completion(image)
        }
    }
}
