//
//  ViewController.swift
//  PhotoLibraryAnalyzer
//
//  Created by Mostafa Abdellateef on 11/23/19.
//  Copyright © 2019 Mostafa Abdellateef. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {

    var allPhotos: PHFetchResult<PHAsset>!
    
    fileprivate let imageManager = PHCachingImageManager()
    private let classificationQueue = DispatchQueue(label: "ClassificationQueue",qos: .userInitiated)
    private let dispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let allPhotosOptions = PHFetchOptions()
//        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
    }
    
    @IBAction func analyzeBtn_didClicked(_ sender: Any) {
        analyzeAllAssets {
            print("Done")
        }
    }
    
    func analyzeAllAssets(completion: @escaping () -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        (0..<allPhotos.count).forEach { idx in
            dispatchGroup.enter()
            let asset = allPhotos.object(at: idx)
            PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options,
                                                      resultHandler: { image, _ in
                                                        guard let image = image else { return }
                                                        self.analyze(image: image)
                                                        
            })
            }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    func analyze(image: UIImage) {
        classificationQueue.async {
            print("Analyzing ******")
            self.dispatchGroup.leave()
        }
    }
}

class ImageClassificationOperation: Operation {
    let image: UIImage
    init(image: UIImage) {
        self.image = image
        super.init()
    }
    
    override func main() {
        // masdf
    }
}
