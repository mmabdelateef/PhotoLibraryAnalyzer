//
//  ThumbnailCollectionViewCell.swift
//  PhotoLibraryAnalyzer
//
//  Created by Mostafa Abdellateef on 11/24/19.
//  Copyright © 2019 Mostafa Abdellateef. All rights reserved.
//

import UIKit
import Photos

class ThumbnailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!

    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
