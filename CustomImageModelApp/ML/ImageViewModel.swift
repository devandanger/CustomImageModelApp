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
  @Published var faceObservations: [VNFaceObservation] = []
  @Published var currentIndex: Int = 0
  @Published var errorMessage: String? = nil
  @Published var detectedFacesImage: UIImage? = nil
  
  // Shared PhotoPickerViewModel
  @Published var photoPickerViewModel: PhotoPickerViewModel
  
  private var cancellables: Set<AnyCancellable> = []
  init(photoPickerViewModel: PhotoPickerViewModel) {
    self.photoPickerViewModel = photoPickerViewModel
  }
  
  @MainActor func detectFaces() {
    currentIndex = 0
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
    
    let faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
      if let error = error {
        DispatchQueue.main.async {
          self?.errorMessage = "Face detection error: \(error.localizedDescription)"
        }
        return
      }
      
      
      let rectangles: [VNFaceObservation] = request.results?.compactMap {
        guard let observation = $0 as? VNFaceObservation else { return nil }
        return observation
      } ?? []
      
      print("Found \(rectangles.count) faces")
      
      rectangles.forEach {
        if let le = $0.landmarks?.leftEye {
          print("Found left eye \(le.normalizedPoints)")
        }
        if let re = $0.landmarks?.rightEye {
          print("Found right eye \(re.normalizedPoints)")
        }
        
        
      }
      
      DispatchQueue.main.async {
        self?.faceObservations = rectangles
        self?.errorMessage = rectangles.isEmpty ? "No faces detected" : nil
      }
    }
    
#if targetEnvironment(simulator)
    let supportedDevices = try! faceDetectionRequest.supportedComputeStageDevices
    if let mainStage = supportedDevices[.main] {
      if let cpuDevice = mainStage.first(where: { device in
        device.description.contains("CPU")
      }) {
        faceDetectionRequest.setComputeDevice(cpuDevice, for: .main)
      }
    }
#endif

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    do {
      try handler.perform([faceDetectionRequest])
    } catch {
      DispatchQueue.main.async {
        self.errorMessage = "Failed to perform detection: \(error.localizedDescription)"
      }
    }
  }
  
  func nextFace() {
    if faceObservations.isEmpty { return }
    currentIndex = (currentIndex + 1) % faceObservations.count
  }
  
  func previousFace() {
    if faceObservations.isEmpty { return }
    currentIndex = (currentIndex - 1 + faceObservations.count) % faceObservations.count
  }
  
  var currentFace: CGRect? {
    guard !faceObservations.isEmpty else { return nil }
    return faceObservations[currentIndex].boundingBox
  }
  
  func adjustOrientation(orient: UIImage.Orientation) -> UIImage.Orientation {
    switch orient {
    case .up: return .downMirrored
    case .upMirrored: return .up
      
    case .down: return .upMirrored
    case .downMirrored: return .down
      
    case .left: return .rightMirrored
    case .rightMirrored: return .left
      
    case .right: return .leftMirrored //check
    case .leftMirrored: return .right
      
    @unknown default: return orient
    }
  }
  
  func drawVisionRect(on image: UIImage?, visionRect: CGRect?) -> UIImage? {
    guard let image = image, let cgImage = image.cgImage else {
      return nil
    }
    guard let visionRect = visionRect else { return image }
    
    // Get image size and prepare the context
    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
    
    UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
    
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    
    //    // Adjust the context based on the image orientation
    //    switch image.imageOrientation {
    //    case .right:
    //        context.translateBy(x: imageSize.width, y: 0)
    //        context.rotate(by: .pi / 2)
    //    case .left:
    //        context.translateBy(x: 0, y: imageSize.height)
    //        context.rotate(by: -.pi / 2)
    //    case .down:
    //        context.translateBy(x: imageSize.width, y: imageSize.height)
    //        context.rotate(by: .pi)
    //    case .upMirrored:
    //        context.translateBy(x: imageSize.width, y: 0)
    //        context.scaleBy(x: -1, y: 1)
    //    case .downMirrored:
    //        context.translateBy(x: 0, y: imageSize.height)
    //        context.scaleBy(x: 1, y: -1)
    //    case .leftMirrored:
    //        context.translateBy(x: imageSize.height, y: 0)
    //        context.scaleBy(x: -1, y: 1)
    //        context.rotate(by: .pi / 2)
    //    case .rightMirrored:
    //        context.translateBy(x: imageSize.width, y: imageSize.height)
    //        context.scaleBy(x: -1, y: 1)
    //        context.rotate(by: -.pi / 2)
    //    default:
    //        break
    //    }
    
    // Draw the original image
    context.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
    
    // Calculate the rectangle using VNImageRectForNormalizedRect
    let correctedRect = VNImageRectForNormalizedRect(visionRect, Int(imageSize.width), Int(imageSize.height))
    
    // Draw the vision rectangle on the image
    UIColor.red.withAlphaComponent(0.3).setFill()
    let rectPath = UIBezierPath(rect: correctedRect)
    rectPath.fill()
    
    UIColor.red.setStroke()
    rectPath.lineWidth = 2.0
    rectPath.stroke()
    
    // Get the resulting UIImage
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    
    logger.debug("original orientation is \(image.imageOrientation.rawValue)")
    // End image context
    UIGraphicsEndImageContext()
    let correctlyOrientedImage = UIImage(cgImage: newImage!.cgImage!, scale: image.scale, orientation: adjustOrientation(orient: image.imageOrientation))
    
    logger.debug("final orientation \(correctlyOrientedImage.imageOrientation.rawValue)")
    
    return correctlyOrientedImage
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

