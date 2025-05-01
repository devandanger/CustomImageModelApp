//
//  VisionProcessing.swift
//  CustomImageModelApp
//
//  Created by Evan Anger on 5/1/25.
//

import Foundation
import Vision
import UIKit

class VisionProcessing: ObservableObject {
    @Published var results: [VNRecognizedTextObservation] = []
    func extract(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(NSError(domain: "TextExtractor", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image format."])))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let results = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(NSError(domain: "TextExtractor", code: -2, userInfo: [NSLocalizedDescriptionKey: "No text found."])))
                return
            }
        

            self.results = results
            let fullText = results
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")

            completion(.success(fullText))
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(error))
            }
        }
    }
}
