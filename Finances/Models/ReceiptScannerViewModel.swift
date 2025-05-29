//
//  ReceiptScannerViewModel.swift
//  Finances
//
//  Created by Martin Lanius on 29.05.25.
//

import SwiftUI
import UIKit

@MainActor
class ReceiptScannerViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isProcessing = false
    @Published var grossTotal: Double?

    var source: ImagePicker.Source = .library

    private let ocrService = OCRService()
    private let extractor = TotalExtractor()

    func process(image: UIImage) {
        self.image = image
        self.isProcessing = true

        ocrService.recognizeText(from: image) { [weak self] rawText in
            guard let self = self else { return }
            if let text = rawText, !text.isEmpty {
                print("OCR recognized text:\n\(text)")
                let total = self.extractor.extractGrossTotal(from: text)
                DispatchQueue.main.async {
                    self.grossTotal = total
                    self.isProcessing = false
                }
            } else {
                print("OCR returned no text or error.")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
}
