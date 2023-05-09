//
//  Double+Extension.swift
//  PhotoValidation
//
//  Created by Emre Dogan on 09/05/2023.
//

import Foundation

extension Double {
	/// Rounds the double to decimal places value
	func rounded(toPlaces places:Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
}
