//
//  ClassificationHeaderCollectionReusableView.swift
//  PhotoLibraryAnalyzer
//
//  Created by Mostafa Abdellateef on 11/24/19.
//  Copyright © 2019 Mostafa Abdellateef. All rights reserved.
//

import UIKit

class ClassificationHeaderCollectionReusableView: UICollectionReusableView {

    @IBOutlet weak var titleLabel: UILabel!
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
}
