//
//  ValidatableImageView.swift
//  PhotoValidation
//
//  Created by Emre Dogan on 09/05/2023.
//

import SwiftUI

struct ValidatableImageView: View {
	let validatableImage: ValidatableImage
	let onTapGesture: () -> Void
	
	var body: some View {
		Image(uiImage: validatableImage.image)
			.resizable()
			.frame(width: 170, height: 170)
			.scaledToFit()
			.overlay(!validatableImage.hasError ? Image(systemName: "checkmark.circle.fill").foregroundColor(.green) : Image(systemName: "xmark.octagon.fill").foregroundColor(.red))
			.onTapGesture(perform: onTapGesture)
	}
}

struct ValidatableImageView_Previews: PreviewProvider {
    static var previews: some View {
		ValidatableImageView(validatableImage: ValidatableImage(image: UIImage(systemName: "heart.fill")!), onTapGesture: {})
    }
}
