//
//  ContentView.swift
//  PhotoValidation
//
//  Created by Emre Dogan on 03/05/2023.
//

import SwiftUI

struct PhotoValidateView: View {
	@StateObject var viewModel = PhotoValidateViewModel()
	
	var body: some View {
		NavigationView {
			VStack {
				ImagePickerView(
					takePictureAction: {
						viewModel.takePicture()
					},
					pickImageAction: {
						viewModel.pickImage()
					}
				)
				
				ValidatableImagesListView(validatableImages: viewModel.chosenValidatableImages) { validatableImage in
					viewModel.showAlert = true
					viewModel.alertMessage = validatableImage.dataMessage
				}
				
				.navigationTitle("Photo Validate")
			}
			.alert(isPresented: $viewModel.showAlert) {
				Alert(title: Text("Validation Result"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		PhotoValidateView()
	}
}


