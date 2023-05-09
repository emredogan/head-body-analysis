//
//  ValidatableImagesListView.swift
//  PhotoValidation
//
//  Created by Emre Dogan on 09/05/2023.
//

import SwiftUI

struct ValidatableImagesListView: View {
	let validatableImages: [ValidatableImage]
	let onTapGesture: (ValidatableImage) -> Void
	
	private let adaptiveColumns = [
		GridItem(.adaptive(minimum: 170))
	]
	
	var body: some View {
		ScrollView {
			LazyVGrid(columns: adaptiveColumns, spacing: 20) {
				ForEach(validatableImages) { validatableImage in
					ValidatableImageView(validatableImage: validatableImage, onTapGesture: { onTapGesture(validatableImage) })
				}
			}
		}
		.padding()
	}
}

struct ValidatableImagesListView_Previews: PreviewProvider {
    static var previews: some View {
		ValidatableImagesListView(validatableImages: [], onTapGesture: {_ in })
    }
}
