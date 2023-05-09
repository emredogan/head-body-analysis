//
//  ImagePicker.swift
//  PhotoValidation
//
//  Created by Emre Dogan on 03/05/2023.
//

import Foundation
import PhotosUI

public class ImagePicker {
	public static let shared = ImagePicker()
	private init() {}
	
	// Delegates
	private var imagePickerDelegate: ImagePickerDelegate?
	private var cameraPickerDelegate: CameraPickerDelegate?
	
	// Current active window
	private let keyWindow = UIApplication
		.shared
		   .connectedScenes
		   .compactMap { ($0 as? UIWindowScene)?.keyWindow }
		   .first

	/**
	 This function allows user to choose a list of images and returns those images

	 - parameter selectionLimit: The maximum number of images that user can choose
	 - parameter completion: A closure that will be called when the user finishes selecting the images.
	 The closure will receive an array of UIImage objects representing the selected images.
	 */
	public func pickImage(selectionLimit: Int, completion: @escaping ([UIImage], TimeInterval) -> Void) {
		guard let rootController = keyWindow?.rootViewController else { return }
		
		var configuration = PHPickerConfiguration()
		// We only allow images to be picked.
		configuration.filter = .images
		configuration.selectionLimit = selectionLimit
				
		imagePickerDelegate = ImagePickerDelegate(completion: { images, timeDelayForPickingImages in
			completion(images, timeDelayForPickingImages) // Send the images and total time in the completion handler
		}, viewController: rootController)
		
		let picker = PHPickerViewController(configuration: configuration)
		picker.delegate = imagePickerDelegate

		// Present the picker on the top most view controller
		rootController.present(picker, animated: true)
	}
	/**
	 This function allows the user to take a picture using the device's camera and returns the captured image.

	 - parameter completion: A closure that will be called when the user captures an image using the camera.
	 The closure will receive an optional UIImage object representing the captured image.
	 If the user cancels or there is an error capturing the image, the closure will receive nil.
	 */
	public func takePicture(completion: @escaping (UIImage?) -> Void) {
		// Camera is not available
		guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
		  return completion(nil)
		}
		
		guard let rootController = keyWindow?.rootViewController else { return }
		
		let cameraImagePicker = UIImagePickerController()
		cameraImagePicker.sourceType = .camera
		cameraImagePicker.allowsEditing = false
		
		cameraPickerDelegate = CameraPickerDelegate(completion: completion, viewController: rootController)

		cameraImagePicker.delegate = cameraPickerDelegate
		rootController.present(cameraImagePicker, animated: true, completion: nil)
	}
}

class CameraPickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	let completion: (UIImage?) -> Void
	weak var viewController: UIViewController?
	
	init(completion: @escaping (UIImage?) -> Void, viewController: UIViewController) {
		self.completion = completion
		self.viewController = viewController
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		picker.dismiss(animated: true, completion: nil)
		guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return completion(nil) }
		completion(image)
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true)
	}
}

class ImagePickerDelegate: PHPickerViewControllerDelegate {
	let completion: ([UIImage], TimeInterval) -> Void
	weak var viewController: UIViewController?
	var startTime: TimeInterval?
	var endTime: TimeInterval?
	
	init(completion: @escaping ([UIImage], TimeInterval) -> Void, viewController: UIViewController) {
		self.completion = completion
		self.viewController = viewController
	}
	
	func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
		picker.dismiss(animated: true)
		startTime = CACurrentMediaTime()
		/// Create a DispatchGroup to keep track of the completion of each item loading
		let group = DispatchGroup()
		var images = [UIImage]()
		
		/// Iterate over each result item and enter the dispatch group to keep track of the item loading
		results.forEach { result in
			group.enter()
			result.itemProvider.loadObject(ofClass: UIImage.self) {reading, error in
				defer {
					group.leave()
				}
				guard let image = reading as? UIImage, error == nil else {
					return
				}
				images.append(image)
			}
		}
		
		/// Iterated through all the images, now we can send them
		group.notify(queue: .main) {
			guard let startTime = self.startTime else { return }
			self.endTime = CACurrentMediaTime() // Set end time here
			guard let endTime = self.endTime else { return }
			let totalTime = endTime - startTime
			self.completion(images, totalTime)
		}
	}
}

