//
//  ImageViewController.swift
//  PhotoLibraryAnalyzer
//
//  Created by Mostafa Abdellateef on 12/28/19.
//  Copyright © 2019 Mostafa Abdellateef. All rights reserved.
//

import UIKit
import Photos

class ImageViewController: UIViewController {

    @IBOutlet weak var imageViwe: UIImageView!
    
    var image: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageViwe.image = image
        // Do any additional setup after loading the view.
    }
    
    convenience init(asset: PHAsset) {
        self.init()
        image = PhotoAssetManager.requestFullSizeImage(for: asset)
    }
}
