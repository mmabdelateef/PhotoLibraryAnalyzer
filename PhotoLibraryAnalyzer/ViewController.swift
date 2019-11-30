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

    static let thumbnailCellIdentifier = "thumbnailCell"
    static let sectionTitledentifier = "classificationTitle"
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    var allPhotos: PHFetchResult<PHAsset>!
    var availableWidth: CGFloat = 0
    var categoriesWithAssets = [String: Set<PHAsset>]()
    
    var data: [(key: String, value: [PHAsset])]? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    fileprivate let imageManager = PHCachingImageManager()
    private let dispatchGroup = DispatchGroup()
    var thumbnailSize = CGSize.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isHidden = true
        collectionView.register(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: ViewController.thumbnailCellIdentifier)
        collectionView.register(UINib(nibName: "ClassificationHeaderCollectionReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ViewController.sectionTitledentifier)
        
        let allPhotosOptions = PHFetchOptions()
//        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        allPhotosOptions.includeAssetSourceTypes = .typeiTunesSynced
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
    }
    
    var cellSize: CGSize = .zero
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let width = view.bounds.inset(by: view.safeAreaInsets).width
        // Adjust the item size if the available width has changed.
        if availableWidth != width {
            availableWidth = width
            let columnCount = (availableWidth / 100).rounded(.towardZero)
            let itemLength = (availableWidth - columnCount - 1) / columnCount
            cellSize = CGSize(width: itemLength, height: itemLength)
            collectionViewFlowLayout.itemSize = cellSize
            collectionViewFlowLayout.headerReferenceSize = CGSize(width: collectionView.bounds.width, height: 90)
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        thumbnailSize = cellSize
    }
    
    @IBAction func analyzeBtn_didClicked(_ sender: Any) {
        analyzeAllAssets {
            print("Done")
            self.data = self.categoriesWithAssets.sorted { $0.value.count > $1.value.count}.map {
                (key: $0.key, value: Array($0.value))
            }
        }
    }
    
    func analyzeAllAssets(completion: @escaping () -> Void) {
//        let options = PHImageRequestOptions()
//        options.deliveryMode = .highQualityFormat
//        options.isNetworkAccessAllowed = true
        (0..<allPhotos.count).forEach { idx in
            dispatchGroup.enter()
            analyze(asset: allPhotos.object(at: idx))
        }
        
        dispatchGroup.notify(queue: .main) {
            completion()
        }
    }
    
    lazy var classificationQueue: OperationQueue = {
      var queue = OperationQueue()
      queue.name = "Download queue"
      queue.maxConcurrentOperationCount = 1
      return queue
    }()
    
    func analyze(asset: PHAsset) {
        print("Start Analyzing *****************")
        let classificationOperation = ImageClassification(asset: asset)
        classificationOperation.completionBlock = {
            print("finish Analyzing *****************")
            print("Results = \(classificationOperation.result!)")
            classificationOperation.result!.forEach {
                if let assets = self.categoriesWithAssets[$0.identifier] {
                    var assetsSet = assets
                    assetsSet.insert(asset)
                    self.categoriesWithAssets[$0.identifier] = assetsSet
                } else {
                    self.categoriesWithAssets[$0.identifier] = [asset]
                }
            }
            self.dispatchGroup.leave()
        }
        classificationQueue.addOperation(classificationOperation)
    }
    
    
    // MARK: Asset Caching
    
    var previousPreheatRect: CGRect = .zero

    fileprivate func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    /// - Tag: UpdateAssets
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }

        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)

        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }

        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in data![indexPath.section].value[indexPath.item] }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in data![indexPath.section].value[indexPath.item] }

        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
    }

    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }

}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data?[section].value.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewController.thumbnailCellIdentifier, for: indexPath) as? ThumbnailCollectionViewCell else {
            assertionFailure()
            return UICollectionViewCell()
        }
        guard let asset = data?[indexPath.section].value[indexPath.item] else {
            assertionFailure()
            return cell
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            // UIKit may have recycled this cell by the handler's activation time.
            // Set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view : UICollectionReusableView! = nil
        if kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ViewController.sectionTitledentifier, for: indexPath) as? ClassificationHeaderCollectionReusableView {
            header.title = data![indexPath.section].key
            return header
        }
        
        return view
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}
