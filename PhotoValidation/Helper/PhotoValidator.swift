import UIKit
import Vision
import CoreImage

enum PhotoValidatorError: Error {
	case faceDetectionFailed
	case tooManyFacesDetected
}

public class PhotoValidator {
	
	private func setupFaceCountRequest(_ imageRequestHandler: VNImageRequestHandler, _ completion:  @escaping (Result<[VNFaceObservation], Error>) -> Void) {
		let faceDetectionRequest = VNDetectFaceRectanglesRequest()

		#if targetEnvironment(simulator)
		faceDetectionRequest.usesCPUOnly = true
		#endif

		do {
			try imageRequestHandler.perform([faceDetectionRequest])
			handleFaceDetectionRequest(request: faceDetectionRequest, error: nil) { result in
				switch result {
				case .success(let observations):
					completion(.success(observations))
				case .failure(let error):
					completion(.failure(error))
				}
			}
		} catch {
			completion(.failure(error))
		}
	}
	
	func setupFaceCaptureQualityRequest(_ imageRequestHandler: VNImageRequestHandler, _ completion: @escaping (Result<[VNFaceObservation], Error>) -> Void) {
		let faceCaptureQualityRequest = VNDetectFaceCaptureQualityRequest()
		do {
			try imageRequestHandler.perform([faceCaptureQualityRequest])
			guard let faceObservations = faceCaptureQualityRequest.results else {
				completion(.failure(PhotoValidatorError.faceDetectionFailed))
				return
			}
			completion(.success(faceObservations))
		} catch {
			completion(.failure(error))
		}
	}

	
	private func handleFaceDetectionRequest(request: VNRequest?, error: Error?, completion: @escaping (Result<[VNFaceObservation], PhotoValidatorError>) -> Void) {
		if let requestError = error as NSError? {
			completion(.failure(.faceDetectionFailed))
			return
		}
		
		DispatchQueue.main.async {
			if let results = request?.results as? [VNFaceObservation] {
				completion(.success(results))
			} else {
				completion(.failure(.faceDetectionFailed))
			}
		}
	}
	
	private func handleFaceCaptureQualityRequest(request: VNRequest?, error: Error?, completion: @escaping (Result<[VNFaceObservation], PhotoValidatorError>) -> Void) {
		if let requestError = error as NSError? {
			completion(.failure(.faceDetectionFailed))
			return
		}
		
		DispatchQueue.main.async {
			if let results = request?.results as? [VNFaceObservation] {
				completion(.success(results))
			} else {
				completion(.failure(.faceDetectionFailed))
			}
		}
	}
	
	func setupFaceDetection(image: UIImage, completion: @escaping (Result<[VNFaceObservation], Error>) -> Void) {
		guard let cgImage = image.cgImage else {
			let error = NSError(domain: "PhotoValidator", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not convert UIImage to CGImage"])
			completion(.failure(error))
			return
		}
		
		let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
		
		setupFaceCountRequest(imageRequestHandler, completion)
	}
	
}
