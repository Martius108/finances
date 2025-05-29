//
//  OCRService.swift
//  Finances
//
//  Created by Martin Lanius on 29.05.25.
//

import Vision
import UIKit
import ImageIO

class OCRService {

    func recognizeText(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            // Helper to get the midY of an observation
            func midY(of obs: VNRecognizedTextObservation) -> CGFloat {
                return obs.boundingBox.origin.y + obs.boundingBox.size.height / 2
            }

            // 1. Sort top-to-bottom, then left-to-right
            let sorted = observations.sorted { o1, o2 in
                let y1 = midY(of: o1), y2 = midY(of: o2)
                if abs(y1 - y2) < 0.02 {
                    return o1.boundingBox.minX < o2.boundingBox.minX
                }
                return y1 > y2
            }

            // 2. Group observations into lines by similar midY
            var linesObs: [[VNRecognizedTextObservation]] = []
            for obs in sorted {
                if let last = linesObs.last,
                   abs(midY(of: obs) - midY(of: last[0])) < 0.02 {
                    linesObs[linesObs.count - 1].append(obs)
                } else {
                    linesObs.append([obs])
                }
            }

            // 3. Build text lines
            let lineStrings = linesObs.map { group in
                group.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
                     .compactMap { $0.topCandidates(1).first?.string }
                     .joined(separator: " ")
            }

            // Join lines and return
            let text = lineStrings.joined(separator: "\n")
            completion(text)
        }
        request.recognitionLevel    = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: orientation,
                                            options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up:            self = .up
        case .down:          self = .down
        case .left:          self = .left
        case .right:         self = .right
        case .upMirrored:    self = .upMirrored
        case .downMirrored:  self = .downMirrored
        case .leftMirrored:  self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}
