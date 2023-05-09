import UIKit
import Vision
import SwiftUI


class PhotoValidateViewModel: ObservableObject {
	@Published var chosenValidatableImages: [ValidatableImage] = []
	@Published var showAlert = false
	@Published var alertMessage = ""
	@Published var isValidationDone = false
	
	private let validator = PhotoValidator()
	
	func addImage(_ image: UIImage) {
		chosenValidatableImages.append(ValidatableImage(image: image))
	}
	
	func takePicture() {
		ImagePicker.shared.takePicture { [self] image in
			if let image = image {
				let validatableImage = ValidatableImage(image: image)
				self.chosenValidatableImages.append(validatableImage)
				validateImages()
			}
		}
	}
	
	func pickImage() {
		ImagePicker.shared.pickImage(selectionLimit: 25) { images,timeInterval  in
			for image in images {
				let validatableImage = ValidatableImage(image: image)
				self.chosenValidatableImages.append(validatableImage)
			}
			
			self.validateImages(passedTime: timeInterval)
		}
	}
	
	func validateImages(passedTime: TimeInterval = 0.0) {
		let startTime = DispatchTime.now()
		print("Start time: \(startTime)")
		let validator = PhotoValidator()
		
		let dispatchGroup = DispatchGroup()
		
		for index in 0..<chosenValidatableImages.count {
			print("Processing index \(index)")
			var validatableImage = chosenValidatableImages[index]
			dispatchGroup.enter()
			validator.setupFaceDetection(image: validatableImage.image) { result in
				switch result {
				case .success(let faceObservations):
					if faceObservations.count == 0 {
						validatableImage.hasError = true
						validatableImage.dataMessage = "No faces found in the image"
						print("Leaving dispatch group for image at index \(index)")
						dispatchGroup.leave()
					} else if faceObservations.count == 1 {
						let confidence = faceObservations.first!.confidence
						validatableImage.dataMessage = "Confidence of a face: \(Double(confidence).rounded(toPlaces: 2))"
						
						if faceObservations.count == 1 {
							validator.setupFaceCaptureQualityRequest(VNImageRequestHandler(cgImage: validatableImage.image.cgImage!, orientation: .up, options: [:])) { result in
								defer {
									print("Leaving dispatch group for image at index for face quality \(index)")
									dispatchGroup.leave()
								}
								switch result {
								case .success(let faceObservations):
									if let faceCaptureQuality = faceObservations.first?.faceCaptureQuality {
										validatableImage.dataMessage += ", Face capture quality: \(Double(faceCaptureQuality).rounded(toPlaces: 2))"
									}
								case .failure(let error):
									print("An error occurred while getting face capture quality for image at index \(index): \(error.localizedDescription)")
								}
							}
						} else {
							validatableImage.hasError = true
							validatableImage.dataMessage = "Error: Too many faces in the image."
							print("Leaving dispatch group for image at index \(index)")
							dispatchGroup.leave()
						}
						
						validatableImage.hasError = false
					} else {
						validatableImage.hasError = true
						validatableImage.dataMessage = "Error: Too many faces in the image."
						dispatchGroup.leave()
						print("Leaving dispatch group for image at index \(index)")
					}
					
				case .failure(let error):
					validatableImage.hasError = true
					validatableImage.dataMessage = "An error occurred while validating the image. \(error.localizedDescription)"
					dispatchGroup.leave()
					print("Leaving dispatch group for image at index \(index)")
				}
				self.chosenValidatableImages[index] = validatableImage
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			let endTime = DispatchTime.now()
			print("End time: \(endTime)")

			let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
			let totalDuration = duration + passedTime
			
			print("Duration is \(duration)")
			print("Passed time is \(passedTime)")
			
			self.showAlert = true

			self.alertMessage = "\(self.chosenValidatableImages.count) images passed validation in \(String(format: "%.2f", totalDuration)) seconds."
		}
	}




}


struct ValidatableImage: Identifiable {
	let id = UUID()
	var image: UIImage
	var hasError: Bool = false
	var dataMessage: String = ""
}

extension Double {
	/// Rounds the double to decimal places value
	func rounded(toPlaces places:Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
}
