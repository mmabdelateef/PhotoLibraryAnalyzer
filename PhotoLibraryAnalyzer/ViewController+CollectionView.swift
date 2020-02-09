//
//  ViewController+CollectionView.swift
//  PhotoLibraryAnalyzer
//
//  Created by Mostafa Abdellateef on 12/2/19.
//  Copyright © 2019 Mostafa Abdellateef. All rights reserved.
//

import Foundation
import UIKit

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
        PhotoAssetManager.shared.requestImage(for: asset) { image in
            // UIKit may have recycled this cell by the handler's activation time.
            // Set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view : UICollectionReusableView! = nil
        if kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ViewController.sectionTitledentifier, for: indexPath) as? ClassificationHeaderCollectionReusableView {
            header.title = "\(data![indexPath.section].key) (\(data![indexPath.section].value.count))"
            return header
        }
        
        return view
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let asset = data?[indexPath.section].value[indexPath.item] else {
            assertionFailure()
            return
        }
        let imageVC = ImageViewController(asset: asset)
        present(imageVC, animated: true)
    }
}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
}

extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}
