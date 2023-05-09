//
//  ValidatableImage.swift
//  PhotoValidation
//
//  Created by Emre Dogan on 09/05/2023.
//

import UIKit

struct ValidatableImage: Identifiable {
	let id = UUID()
	var image: UIImage
	var hasError: Bool = false
	var dataMessage: String = ""
}
