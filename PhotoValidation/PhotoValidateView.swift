//
//  ContentView.swift
//  PhotoValidation
//
//  Created by Emre Dogan on 03/05/2023.
//

import SwiftUI

struct PhotoValidateView: View {
	@StateObject var viewModel = PhotoValidateViewModel()
	private let adaptiveColumns = [
		GridItem(.adaptive(minimum: 170))
	]
	
	var body: some View {
		NavigationView {
			VStack {
				HStack {
					Button("CAMERA") {
						ImagePicker.shared.takePicture { image in
							if let image = image {
								let validatableImage = ValidatableImage(image: image)
								viewModel.chosenValidatableImages.append(validatableImage)
								viewModel.validateImages()
							}
						}
					}
					
					Button("GALLERY") {
						ImagePicker.shared.pickImage(selectionLimit: 25) { images,timeInterval  in
							for image in images {
								let validatableImage = ValidatableImage(image: image)
								viewModel.chosenValidatableImages.append(validatableImage)
								
							}
							
							print("TIMER STARTS")
							viewModel.validateImages(passedTime: timeInterval)
						}
					}
				}
				ScrollView {
					LazyVGrid(columns: adaptiveColumns, spacing: 20) {
						ForEach(viewModel.chosenValidatableImages) { validatableImage in
							Image(uiImage: validatableImage.image)
								.resizable()
								.frame(width: 170, height: 170)
								.overlay(!validatableImage.hasError ? Image(systemName: "checkmark.circle.fill").foregroundColor(.green) : Image(systemName: "xmark.octagon.fill").foregroundColor(.red))
								.onTapGesture {
									viewModel.showAlert = true
									viewModel.alertMessage = validatableImage.dataMessage
								}
						}
					}
				}
				.padding()
				.navigationTitle("Photo Validate")
			}
			.alert(isPresented: $viewModel.showAlert) {
							Alert(title: Text("Validation Result"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
						}
		}
	}
	
	struct ContentView_Previews: PreviewProvider {
		static var previews: some View {
			PhotoValidateView()
		}
	}
}
