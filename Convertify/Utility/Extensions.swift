//
//  Extensions.swift
//  Convertify
//
//  Created by Nwachukwu Ejiofor on 29/11/2020.
//

import Foundation
import Alamofire
import SwiftyJSON

fileprivate var aView: UIView?

extension UIViewController {
	static var API_KEY = "99fad31a9943ed2767b00a35416cd0c2"
	static var baseUrl = "http://data.fixer.io/api/"
	static var GET_EXCHANGE_RATE = "latest"
	
	func showToast(controller: UIViewController, message: String, seconds: Double) {
		let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
		alert.view.backgroundColor = .white
		alert.view.alpha = 0.1
		alert.view.layer.cornerRadius = 15
		
		controller.present(alert, animated: true)
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
			alert.dismiss(animated: true, completion: nil)
		}
	}
	
	func showSpinner() {
		aView = UIView(frame: self.view.bounds)
		aView?.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
		
		let spinner = UIActivityIndicatorView(style: .large)
		spinner.color = UIColor.systemBlue
		spinner.center = aView!.center
		spinner.startAnimating()
		aView?.addSubview(spinner)
		self.view.addSubview(aView!)
		
		Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { (t) in
			self.removeSpinner()
		}
	}
	
	func removeSpinner() {
		aView?.removeFromSuperview()
		aView = nil
	}
	
	func get(endPoint: String, parameters: [String : Any]? = [:], headers: [String : Any]? = [:], completion: @escaping (_ success: Bool, _ object: SwiftyJSON.JSON?) -> ()) {
		var headersss: HTTPHeaders = [
			"Accept": "application/json"
		]
		headers!.forEach {
			headersss[$0.key] = $0.value as? String
		}
		let url = UIViewController.baseUrl + endPoint
		Alamofire.request(url, method: .get, parameters: parameters!.count == 0 ? nil : parameters, headers: headersss).validate(statusCode: 200..<299).responseJSON { (responseData) -> Void in
			if((responseData.result.value) != nil) {
				switch responseData.result {
				case .success(let data):
					let result = JSON(data)
					completion(true,result)
				case .failure(let error):
					let result = JSON(error.localizedDescription);
					if let error = error as? AFError {
						switch error {
						case .invalidURL(let url):
							completion(false, result)
							print("Invalid URL: \(url) - \(error.localizedDescription)")
						case .parameterEncodingFailed(let reason):
							completion(false, result)
							print("Parameter encoding failed: \(error.localizedDescription)")
							print("Failure Reason: \(reason)")
						case .multipartEncodingFailed(let reason):
							completion(false, result)
							print("Multipart encoding failed: \(error.localizedDescription)")
							print("Failure Reason: \(reason)")
						case .responseValidationFailed(let reason):
							completion(false, result)
							print("Response validation failed: \(error.localizedDescription)")
							print("Failure Reason: \(reason)")
							
							switch reason {
							case .dataFileNil, .dataFileReadFailed:
								print("Downloaded file could not be read")
							case .missingContentType(let acceptableContentTypes):
								print("Content Type Missing: \(acceptableContentTypes)")
							case .unacceptableContentType(let acceptableContentTypes, let responseContentType):
								print("Response content type: \(responseContentType) was unacceptable: \(acceptableContentTypes)")
							case .unacceptableStatusCode(let code):
								print("Response status code was unacceptable: \(code)")
							}
						case .responseSerializationFailed(let reason):
							print("Response serialization failed: \(error.localizedDescription)")
							print("Failure Reason: \(reason)")
						}
						print("Underlying error: \(String(describing: error.underlyingError))")
					} else if let error = error as? URLError {
					   completion(false, JSON(error))
					} else {
						completion(false, JSON(error))
					}
				}
			}
		}
	}
}

extension UIView {
	func applyBorder(color: UIColor, width: Int, radius: Int) {
		self.layer.cornerRadius = CGFloat(radius)
		self.layer.borderWidth = CGFloat(width)
		self.layer.borderColor = color.cgColor
		self.clipsToBounds = true
	}
	
//	func startShimmer() {
//		let light = UIColor.white.cgColor
//		let alpha = UIColor(red: 206/255, green: 10/255, blue: 10/255, alpha: 0.7).cgColor
//		let gradient = CAGradientLayer()
//		gradient.frame = CGRect(x: -self.bounds.size.width, y: 0, width: 3 * self.bounds.size.width, height: self.bounds.size.height)
//		gradient.colors = [light, alpha, light]
//		gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
//		gradient.endPoint = CGPoint(x: 1.0,y: 0.525)
//		gradient.locations = [0.35, 0.50, 0.65]
//		self.layer.mask = gradient
//		let animation = CABasicAnimation(keyPath: "locations")
//		animation.fromValue = [0.0, 0.1, 0.2]
//		animation.toValue = [0.8, 0.9,1.0]
//		animation.duration = 1.5
//		animation.repeatCount = HUGE
//		gradient.add(animation, forKey: "shimmer")
//	}
//	
//	func stopShimmer() {
//		self.layer.mask = nil
//	}
}
