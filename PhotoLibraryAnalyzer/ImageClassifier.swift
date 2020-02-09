//
//  ImageClassifier.swift
//  PhotoLibraryAnalyzer
//
//  Created by Mostafa Abdellateef on 11/24/19.
//  Copyright © 2019 Mostafa Abdellateef. All rights reserved.
//

import Foundation
import Vision
import CoreML
import UIKit
import Photos


struct ClassificationResult: CustomStringConvertible {
    let confidence: Float
    let identifier: String
    
    var description: String {
        return "\(identifier) [\(confidence)]"
    }
}

class ImageClassification: Operation {
    private let asset: PHAsset
    private(set) var result: [ClassificationResult]?
    
    static let phImageRequestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        return options
    } ()
        
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    let dispatchGroup = DispatchGroup()
    override func main() {
        dispatchGroup.enter()
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: ImageClassification.phImageRequestOptions,
                                                  resultHandler: { image, _ in
                                                    guard let image = image else {
                                                        print("Can't retreive asset image")
                                                        self.dispatchGroup.leave()
                                                        return
                                                    }
                                                    self.performClassifications(for: image)
        })
        dispatchGroup.wait()
    }
    
    deinit {
        print("Deinit")
    }
    
    
    /// - Tag: MLModelSetup
        
    static let models = [
        MobileNetV2().model,        
    ]
    
    static let classificationRequests: [VNCoreMLRequest] = {
            return models.map {
                do {
                let model = try VNCoreMLModel(for: $0)
                let request = VNCoreMLRequest(model: model)
                request.imageCropAndScaleOption = .centerCrop
                return request
                } catch {
                    fatalError("Failed to load Vision ML model: \(error)")
                }
            }
       }()
    
    static let classificationRequest2: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MobileNetV2().model)
            let request = VNCoreMLRequest(model: model)
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    /// - Tag: PerformRequests
    private func performClassifications(for image: UIImage) {
        
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform(ImageClassification.classificationRequests)
                self.processRequests(ImageClassification.classificationRequests)
            } catch {
                /*
                 This handler catches general image processing errors. The `classificationRequest`'s
                 completion handler `processClassifications(_:error:)` catches errors specific
                 to processing that request.
                 */
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    /// - Tag: ProcessClassifications
    private func processRequests(_ requests: [VNRequest]) {
        guard let observations = (requests.compactMap { $0.results }.flatMap { $0 }) as? [VNClassificationObservation] else {
            print("Unable to classify image")
            self.dispatchGroup.leave()
            return
        }
        
        processObservations(observations)
    }
    
    private func processObservations(_ observations: [VNClassificationObservation]) {
        defer {
            dispatchGroup.leave()
        }
        
        guard !observations.isEmpty else {
            print("Nothing reconized")
            return
        }
        
        result = observations
            .filter{ $0.confidence > 0.15 }
            .map{ ClassificationResult(confidence: $0.confidence, identifier: $0.identifier) }
    }
    
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}
