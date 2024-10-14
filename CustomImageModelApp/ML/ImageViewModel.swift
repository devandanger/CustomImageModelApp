//
//  ImageViewModel.swift
//  CustomImageModelApp
//
//  Created by Evan Anger on 10/14/24.
//

import SwiftUI
import Combine
import Vision
import OSLog

let logger = Logger() as Logger

class ImageViewModel: ObservableObject {
    @Published var observations: [VNClassificationObservation] = []
    @Published var errorMessage: String? = nil
    @Published var identifier: String? = nil

    // Shared PhotoPickerViewModel
    @Published var photoPickerViewModel: PhotoPickerViewModel
    private let mlModel: VNCoreMLModel
    
  
  private var cancellables: Set<AnyCancellable> = []
  init(photoPickerViewModel: PhotoPickerViewModel) {
      self.photoPickerViewModel = photoPickerViewModel
      let config = MLModelConfiguration()
      let coreMLModel = try! CatsVsDog_v1(configuration: config)
      mlModel = try! VNCoreMLModel(for: coreMLModel.model)
  }
  
    @MainActor func runInference() {
        guard let image = photoPickerViewModel.selectedPhoto?.image else {
            DispatchQueue.main.async {
                self.errorMessage = "No image available"
            }
            return
        }
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to convert UIImage to CGImage"
            }
            return
        }
        
        let classificationRequest = VNCoreMLRequest(model: mlModel) { request, error in
            guard let results = request.results else {
                self.observations = []
                return
            }
            
        
            self.observations = results.compactMap {
                
                guard let classificationObservation = $0 as? VNClassificationObservation else {
                    return nil
                }
                print("Result: \(classificationObservation.confidence) \(classificationObservation.identifier)")
                return classificationObservation
            }.sorted { $0.confidence > $1.confidence }
            
            if !self.observations.isEmpty {
                self.identifier = self.observations.first?.identifier
            }
        }

        #if targetEnvironment(simulator)
        if #available(iOS 17.0, *) {
          let allDevices = MLComputeDevice.allComputeDevices
          for device in allDevices {
              if case .cpu = device {
                  classificationRequest.setComputeDevice(device, for: .main)
                  break
              }
          }
        } else {
          // Fallback on earlier versions
            classificationRequest.usesCPUOnly = true
        }
        #endif
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([classificationRequest])
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to perform detection: \(error.localizedDescription)"
            }
        }
    }
}

extension Publisher {
    func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let output = await transform(value)
                    promise(.success(output))
                }
            }
        }
    }
}

