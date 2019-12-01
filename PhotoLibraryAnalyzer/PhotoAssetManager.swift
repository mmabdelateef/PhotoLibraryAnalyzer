//
//  PhotoAssetManager.swift
//  PhotoLibraryAnalyzer
//
//  Created by Mostafa Abdellateef on 12/7/19.
//  Copyright © 2019 Mostafa Abdellateef. All rights reserved.
//

import UIKit
import Photos

class PhotoAssetManager {
    
    private(set) var allPhotos: PHFetchResult<PHAsset>!
    
    private let imageManager = PHCachingImageManager()

    static let shared = PhotoAssetManager()
    static let thumbnailSize = CGSize(width: 224, height: 224)
    
    private init() {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        allPhotosOptions.includeAssetSourceTypes = .typeiTunesSynced
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
    }
    
    func requestImage(for asset: PHAsset, isSyncronuos: Bool = false, highQuality: Bool = true, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = isSyncronuos
        
        
        imageManager.requestImage(for: asset, targetSize: PhotoAssetManager.thumbnailSize, contentMode: .aspectFit, options: options) { image, _ in
            completion(image)
        }
    }

    // MARK: Asset Caching
    

    func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
    }
    
    func updateCachedAssets(addedAssets: [PHAsset], removedAssets: [PHAsset]) {


        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: PhotoAssetManager.thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: PhotoAssetManager.thumbnailSize, contentMode: .aspectFill, options: nil)
        }
}
