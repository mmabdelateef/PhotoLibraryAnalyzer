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
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var analyzeBtn: UIButton!
    
    private var categoriesWithAssets = [String: Set<PHAsset>]()
    private let dispatchGroup = DispatchGroup()
    
    /// variable used to store last rect used  for caching
    var previousPreheatRect: CGRect = .zero
    var cellSize: CGSize = .zero
    
    private(set) var data: [(key: String, value: [PHAsset])]? {
        didSet {
            collectionView.reloadData()
        }
    }
    
    private var state: State! {
        didSet {
            switch state {
            case .initial:
                analyzeBtn.isHidden = false
                collectionView.isHidden = true
                loadingLabel.isHidden = true
            case .loading:
                analyzeBtn.isHidden = true
                collectionView.isHidden = true
                loadingLabel.isHidden = false
            case .displayingResult:
                analyzeBtn.isHidden = true
                collectionView.isHidden = false
                loadingLabel.isHidden = true
            case .none:
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        state = .initial
        collectionView.register(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: ViewController.thumbnailCellIdentifier)
        collectionView.register(UINib(nibName: "ClassificationHeaderCollectionReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ViewController.sectionTitledentifier)
    }
        
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let width = view.bounds.width
        let columnCount: CGFloat = 3
        let itemLength = (width - columnCount - 1) / columnCount
        cellSize = CGSize(width: itemLength, height: itemLength)
        collectionViewFlowLayout.itemSize = cellSize
        collectionViewFlowLayout.headerReferenceSize = CGSize(width: collectionView.bounds.width, height: 90)
    }
    
    @IBAction func analyzeBtn_didClicked(_ sender: Any) {
        state = .loading
        analyzeAllAssets {
            self.data = self.categoriesWithAssets.sorted { $0.value.count > $1.value.count}.map {
                (key: $0.key, value: Array($0.value))
            }
            self.state = .displayingResult
        }
    }
    
    private var allPhotos: PHFetchResult<PHAsset> = PhotoAssetManager.shared.allPhotos
    
    func analyzeAllAssets(completion: @escaping () -> Void) {
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
    
    var count = 0
    func analyze(asset: PHAsset) {
        print("Start Analyzing *****************")
        let classificationOperation = ImageClassification(asset: asset)
        classificationOperation.completionBlock = {
            print("finish Analyzing *****************")
            print("Results = \(classificationOperation.result!)")
            self.count += 1
            DispatchQueue.main.async {
                self.loadingLabel.text = "Analyzing Photos libaray \n \(self.count) of \(self.allPhotos.count)"
            }
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
}

extension ViewController {
    enum State {
        case initial
        case loading
        case displayingResult
    }
}
