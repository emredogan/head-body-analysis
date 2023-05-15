import UIKit
import Vision
import SwiftUI

class PhotoValidateViewModel: ObservableObject {
	@Published var chosenValidatableImages: [ValidatableImage] = []
	@Published var showAlert = false
	@Published var alertMessage = ""
	@Published var isValidationDone = false
	@Published var fullBodyImageExists = false
	@Published var chestUpBodyImageExists = false
	@Published var smileExists = false
	
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
		ImagePicker.shared.pickImage(selectionLimit: 25) { images,timeDelayForPickingImages  in
			for image in images {
				let validatableImage = ValidatableImage(image: image)
				self.chosenValidatableImages.append(validatableImage)
			}
			
			self.validateImages(passedTime: timeDelayForPickingImages)
		}
	}
	
	func detectSmile(ciImage: CIImage) {
		
		let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])

		let options: [String : AnyObject] = [CIDetectorSmile: true as AnyObject, CIDetectorEyeBlink: true as AnyObject]
		let features = detector?.features(in: ciImage, options: options)

		for feature in features as! [CIFaceFeature] {
			if feature.hasSmile {
				self.smileExists = true
			}
		print("Smile: (\(feature.hasSmile ? "YES" : "NO" ) )")
		}
	}
	
	func detectBody(requestHandler: VNImageRequestHandler) {
		// Create a new request to recognize a human body pose.
		let request = VNDetectHumanBodyPoseRequest(completionHandler: bodyPoseHandler)

		do {
			// Perform the body pose-detection request.
			try requestHandler.perform([request])
		} catch {
			print("Unable to perform the request: \(error).")
		}
	}
	
	func bodyPoseHandler(request: VNRequest, error: Error?) {
		guard let observations =
				request.results as? [VNHumanBodyPoseObservation] else {
			return
		}
		
		// Process each observation to find the recognized body pose points.
		observations.forEach { processObservation($0) }
	}
	
	func processObservation(_ observation: VNHumanBodyPoseObservation) {
		var headObserved = false
		var leftFootObserved = false
		var rightFootObserved = false
		var hipObserved = false
		
		for joint in observation.availableJointNames {
			guard let point = try? observation.recognizedPoint(joint)  else {
				return
			}
			if joint.rawValue.rawValue == "head_joint" && point.confidence > 0 {
				headObserved = true
			}
			
			if joint.rawValue.rawValue == "right_foot_joint" && point.confidence > 0 {
				rightFootObserved = true
			}
			
			if joint.rawValue.rawValue == "right_foot_joint" && point.confidence > 0 {
				leftFootObserved = true
			}
			
			if joint.rawValue.rawValue == "root" && point.confidence > 0 {
				hipObserved = true
			}
		
		}
		
		if headObserved && leftFootObserved && rightFootObserved {
			fullBodyImageExists = true
		}
		
		if headObserved && hipObserved && !leftFootObserved && !rightFootObserved {
			chestUpBodyImageExists = true
		}
		
	}
	
	func validateImages(passedTime: TimeInterval = 0.0) {
		let startTime = DispatchTime.now()
		let validator = PhotoValidator()
		
		let dispatchGroup = DispatchGroup()
		
	outerLoop: for index in 0..<chosenValidatableImages.count {
			print("Processing index \(index)")
			var validatableImage = chosenValidatableImages[index]
			dispatchGroup.enter()
			
			/// First we check how many faces are visible in the image.
			validator.setupFaceDetection(image: validatableImage.image) { result in
				switch result {
					case .success(let faceObservations):
						/// If there is no face in the image, it is a fail case no more further processing and leave the dispatch queue.
						if faceObservations.count == 0 {
							validatableImage.hasError = true
							validatableImage.dataMessage = "No faces found in the image"
							print("Leaving dispatch group for image at index \(index)")
							dispatchGroup.leave()
						} else if faceObservations.count == 1 {
							let handler = VNImageRequestHandler(ciImage: CIImage(cgImage: validatableImage.image.cgImage!))
							
							let ciImage = CIImage(cgImage: validatableImage.image.cgImage!)
							self.detectSmile(ciImage: ciImage)
							self.detectBody(requestHandler: handler)

							let request = VNClassifyImageRequest()
							try? handler.perform([request])
							let results = request.results
							
							var count = 0
							
							for result in results! {
								
								if result.identifier == "headsets" {
									print("FOUND")
									print(result.confidence)
								}
								
								if result.identifier == "airpods" {
									print("FOUND")
									print(result.confidence)
								}
							}
							
							for result in results! {
								print(result)
								if result.identifier == "sunglasses" && result.confidence > 0.65 {
									validatableImage.dataMessage = "Please take a photo without sunglasses"
									validatableImage.hasError = true
									dispatchGroup.leave()
									break

								} else if result.identifier == "hat"  && result.confidence > 0.65 {
									validatableImage.dataMessage = "Please take a photo without a hat"
									validatableImage.hasError = true
									print(result.confidence)
									dispatchGroup.leave()
									break

								} else if result.identifier == "headphones"  && result.confidence > 0.25 {
									validatableImage.dataMessage = "Please take a photo without a headphones"
									validatableImage.hasError = true
									print(result.confidence)
									dispatchGroup.leave()
									break
								}
							
								count += 1
								if count == 20 {
									break
								}
							}
							
							if validatableImage.hasError {
								break
							}
							
							let confidence = faceObservations.first!.confidence
							validatableImage.dataMessage += "Confidence of a face: \(Double(confidence).rounded(toPlaces: 2))"
							
							/// If there is only one face in the image, we do further processing to check the confidence and face capture quality.
							validator.setupFaceCaptureQualityRequest(VNImageRequestHandler(cgImage: validatableImage.image.cgImage!, orientation: .up, options: [:])) { result in
								defer {
									/// For both success and failure cases we want to leave the dispatch queue.
									print("Leaving dispatch group for image at index for face quality \(index)")
									dispatchGroup.leave()
								}
								switch result {
									case .success(let faceObservations):
										if let faceCaptureQuality = faceObservations.first?.faceCaptureQuality {
											validatableImage.hasError = false
											validatableImage.dataMessage += ", Face capture quality: \(Double(faceCaptureQuality).rounded(toPlaces: 2))"
										}
									case .failure(let error):
										/// We need to decide what to do if the capture quality fails.
										validatableImage.hasError = true
										print("An error occurred while getting face capture quality for image at index \(index): \(error.localizedDescription)")
								}
							}
						} else if faceObservations.count > 1{
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
		
		/// Once we finished processing all the images we calculate the total time top p
		dispatchGroup.notify(queue: .main) {
			let endTime = DispatchTime.now()
			let duration = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
			let totalDuration = duration + passedTime
			
			self.showAlert = true
			self.alertMessage = "\(self.chosenValidatableImages.count) images passed validation in \(String(format: "%.2f", totalDuration)) seconds. FULL BODY OBSERVED: \(self.fullBodyImageExists), HALF BODY OBSERVED: \(self.chestUpBodyImageExists) SMILE OBSERVED: \(self.smileExists)"
		}
	}
}
