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


struct ClassificationResult: CustomStringConvertible {
    let confidence: Float
    let identifier: String
    
    var description: String {
        return "\(identifier) [\(confidence)]"
    }
}

class ImageClassification: Operation {
    private let image: UIImage
    private(set) var result: [ClassificationResult]? 
    
    init(image: UIImage) {
        self.image = image
    }
    
    let dispatchGroup = DispatchGroup()
    override func main() {
        dispatchGroup.enter()
        performClassifications(for: image)
        dispatchGroup.wait()
    }
    
    deinit {
        print("Deinit")
    }
    
    
    /// - Tag: MLModelSetup
       private lazy var classificationRequest: VNCoreMLRequest = {
           do {
               /*
                Use the Swift class `MobileNet` Core ML generates from the model.
                To use a different Core ML classifier model, add it to the project
                and replace `MobileNet` with that model's generated Swift class.
                */
               let model = try VNCoreMLModel(for: MobileNetV2().model)
               
               let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                   self?.processClassifications(for: request, error: error)
               })
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
                try handler.perform([self.classificationRequest])
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
    private func processClassifications(for request: VNRequest, error: Error?) {
        defer {
            dispatchGroup.leave()
        }
        
        guard let classifications = request.results as? [VNClassificationObservation] else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        
        
        guard !classifications.isEmpty else {
            print("Nothing reconized")
            return
        }
        
        result = classifications
            .filter{ $0.confidence > 0.3 }
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
