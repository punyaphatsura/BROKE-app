//
//  PhotoFetcher.swift
//  Meow-Jod-Clone-App
//
//  Created by Punyaphat Surakiatkamjorn on 12/5/2568 BE.
//

import Foundation
import SwiftUI
import Photos

class PhotoFetcher: ObservableObject {
    @Published var images: [UIImage] = []
    @Published var isLoadingComplete = false
    
    private let imageManager = PHCachingImageManager()
    private let albumNames = ["SCB Easy", "MAKE by KBank", "K PLUS", "Krungthai NEXT"]
    private var totalAssetsToLoad = 0
    private var loadedAssetsCount = 0

    init() {
        requestPermissionAndFetch()
    }

    private func requestPermissionAndFetch() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized || status == .limited {
                self.fetchImagesFromAlbums()
            }
        }
    }

    private func fetchImagesFromAlbums() {
        totalAssetsToLoad = 0
        loadedAssetsCount = 0
        
        for albumName in albumNames {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "title = %@", albumName)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            
            guard let album = collections.firstObject else { 
                continue 
            }
            let assets = PHAsset.fetchAssets(in: album, options: nil)

            totalAssetsToLoad += assets.count

            assets.enumerateObjects { asset, _, _ in
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                requestOptions.deliveryMode = .highQualityFormat

                let targetSize = CGSize(width: 1200, height: 2400)
                self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                    if let image = image {
                        DispatchQueue.main.async {
                            self.images.append(image)
                            self.loadedAssetsCount += 1
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.loadedAssetsCount += 1
                        }
                    }
                }
            }
        }
        self.isLoadingComplete = true
    }
}
