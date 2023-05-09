//
//  ImagePickerView.swift
//  PhotoValidation
//
//  Created by Emre Dogan on 09/05/2023.
//

import SwiftUI

struct ImagePickerView: View {
	let takePictureAction: () -> Void
	let pickImageAction: () -> Void
	
	var body: some View {
		HStack {
			Button("CAMERA", action: takePictureAction)
			Button("GALLERY", action: pickImageAction)
		}
	}
}

struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
		ImagePickerView(takePictureAction: {}, pickImageAction: {})
    }
}
