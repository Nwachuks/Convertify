//
//  HomeViewController.swift
//  Convertify
//
//  Created by Nwachukwu Ejiofor on 29/11/2020.
//

import UIKit
import DropDown
import FlagKit

class HomeViewController: UIViewController, UITextFieldDelegate {
	@IBOutlet weak var signUpBtn: UIButton!
	@IBOutlet weak var convertBtn: UIButton!
	@IBOutlet weak var baseValueView: UIView!
	@IBOutlet weak var baseValueTextField: UITextField!
	@IBOutlet weak var baseValueLabel: UILabel!
	@IBOutlet weak var baseCurrencyView: UIView!
	@IBOutlet weak var baseCurrencyImage: UIImageView!
	@IBOutlet weak var baseCurrencyLabel: UILabel!
	@IBOutlet weak var exchangeValueView: UIView!
	@IBOutlet weak var exchangeValueTextField: UITextField!
	@IBOutlet weak var exchangeValueLabel: UILabel!
	@IBOutlet weak var exchangeCurrencyView: UIView!
	@IBOutlet weak var exchangeCurrencyImage: UIImageView!
	@IBOutlet weak var exchangeCurrencyLabel: UILabel!
	@IBOutlet weak var infoLabel: UILabel!
	@IBOutlet weak var infoBtn: UIButton!
	
	var baseValue = 0.0
	var exchangeValue = 0.0
	var currency = "USD"
	var isOtherCurrency = false
	var otherRate = 1.0
	var currencies = ["USD", "AED", "AFN", "ALL", "AMD", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", "BTN", "BWP", "BYN", "BZD", "CAD", "CDF", "CHF", "CLP", "CNY", "COP", "CRC", "CUP", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD", "FKP", "GBP", "GEL", "GGP", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS", "IMP", "INR", "IQD", "IRR", "ISK", "JEP", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KPW", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LTL", "LVL", "LYD", "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRO", "MUR", "MVR", "MWK", "MXN", "MYR", "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR", "PLN", "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD", "SHP", "SLL", "SOS", "SRD", "STD", "SVC", "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "UYU", "UZS", "VEF", "VND", "VUV", "WST", "XAF", "XCD", "XDR", "XOF", "XPF", "YER", "ZAR", "ZMK", "ZMW", "ZWL"]
	let baseCurrencyDropDown = DropDown()
	let exchangeCurrencyDropDown = DropDown()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		disableConvert()
		setup()
		infoLabel.isHidden = true
		infoBtn.isHidden = true
		
		// Set default flags
		baseCurrencyImage.image = Flag(countryCode: "EU")?.image(style: .circle)
		exchangeCurrencyImage.image = Flag(countryCode: "US")?.image(style: .circle)
		
		// Setup currency dropdowns
		setupExchangeCurrencyDropdown()
		setupBaseCurrencyDropdown()
    }
    
	@IBAction func signUpBtnTapped(_ sender: UIButton) {
		
	}
	
	@IBAction func infoBtnTapped(_ sender: UIButton) {
		let alert = UIAlertController(title: nil, message: "Rates are according to the mid-market values in real time", preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		alert.addAction(okAction)
		present(alert, animated: true, completion: nil)
	}
	
	@IBAction func convertBtnTapped(_ sender: UIButton) {
		if let baseValue = Double(baseValueTextField.text!) {
			let param = "?access_key=\(UIViewController.API_KEY)&symbols=\(currency)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
			// Call 'latest' endpoint to get conversion rates
			get(endPoint: UIViewController.GET_EXCHANGE_RATE+param) { (success, data) in
				if (success) {
					let apiData = data!
//					print(apiData)
					let currency = Currency()
					currency.name = apiData["base"].stringValue
					currency.rate = apiData["rates"]["\(self.currency)"].doubleValue
					
					// Get timestamp and convert to UTC time
					let time = apiData["timestamp"].doubleValue
					let date = Date(timeIntervalSince1970: time)
					let dateFormatter = DateFormatter()
					dateFormatter.dateFormat = "HH:mm"
					dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
					let utcTime = dateFormatter.string(from: date)
					
					if (self.isOtherCurrency) {
						// Using Euro to calibrate conversion
						self.exchangeValue = baseValue * (currency.rate / self.otherRate)
						self.isOtherCurrency = false
					} else {
						self.exchangeValue = baseValue * currency.rate
					}
					DispatchQueue.main.async {
						// Display value to 6 d.p
						self.exchangeValueTextField.text = String(format: "%.6f", self.exchangeValue)
						self.infoLabel.text = "Mid-market exchange rate at \(utcTime) UTC"
						self.infoLabel.isHidden = false
						self.infoBtn.isHidden = false
					}
				}
			}
		} else {
			// Invalid base value
			print("Invalid input")
			showToast(controller: self, message: "Invalid input", seconds: 2.0)
		}
	}
	
	// MARK: TextField Delegate Methods
	@objc func textFieldDidChange(textField: UITextField) {
		if textField.text!.count > 0 {
			enableConvert()
		} else {
			// Base value textfield is blank
			disableConvert()
		}
	}
	
	@objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
	}
	
	func setup() {
		// Tap to dismiss keyboard
		let viewTap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
		view.addGestureRecognizer(viewTap)
		
		baseValueView.applyBorder(color: .clear, width: 0, radius: 5)
		exchangeValueView.applyBorder(color: .clear, width: 0, radius: 5)
		baseCurrencyView.applyBorder(color: .systemGray5, width: 1, radius: 5)
		exchangeCurrencyView.applyBorder(color: .systemGray5, width: 1, radius: 5)
		convertBtn.applyBorder(color: .clear, width: 0, radius: 5)
		infoBtn.applyBorder(color: .clear, width: 0, radius: Int(infoBtn.frame.height/2))
		
		// TextFields
		baseValueTextField.delegate = self
		baseValueTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
		baseValueTextField.applyBorder(color: .clear, width: 0, radius: 0)
		exchangeValueTextField.delegate = self
		exchangeValueTextField.applyBorder(color: .clear, width: 0, radius: 0)
		
		// Make flag images rounded corners
		baseCurrencyImage.applyBorder(color: .clear, width: 0, radius: Int(baseCurrencyImage.frame.height/2))
		exchangeCurrencyImage.applyBorder(color: .clear, width: 0, radius: Int(exchangeCurrencyImage.frame.height/2))
	}
	
	func disableConvert() {
		convertBtn.isUserInteractionEnabled = false
		convertBtn.alpha = 0.3
	}
	
	func enableConvert() {
		convertBtn.isUserInteractionEnabled = true
		convertBtn.alpha = 1.0
	}
	
	func setupExchangeCurrencyDropdown() {
		exchangeCurrencyDropDown.dataSource = currencies
		exchangeCurrencyDropDown.anchorView = exchangeCurrencyView
		exchangeCurrencyDropDown.direction = .any
		let exchangeCurrencyTap = UITapGestureRecognizer(target: self, action: #selector(showExchangeCurrencyDropdown))
		exchangeCurrencyView.addGestureRecognizer(exchangeCurrencyTap)
		exchangeCurrencyDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
			// Update exchange value & currency fields
			self.exchangeValueTextField.text = ""
			self.exchangeValueLabel.text = item
			self.exchangeCurrencyLabel.text = item
			self.currency = item
			setFlag(item: item, imageView: self.exchangeCurrencyImage)
		}
	}
	
	func setupBaseCurrencyDropdown() {
		baseCurrencyDropDown.dataSource = currencies
		baseCurrencyDropDown.anchorView = baseCurrencyView
		baseCurrencyDropDown.direction = .any
		let baseCurrencyTap = UITapGestureRecognizer(target: self, action: #selector(showBaseCurrencyDropdown))
		baseCurrencyView.addGestureRecognizer(baseCurrencyTap)
		baseCurrencyDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
			// Update base currency fields
			self.baseValueTextField.text = ""
			self.disableConvert()
			self.exchangeValueTextField.text = ""
			self.baseValueLabel.text = item
			self.baseCurrencyLabel.text = item
			setFlag(item: item, imageView: self.baseCurrencyImage)
			
			// Call endpoint to get Euro conversion value for base currency
			let param = "?access_key=\(UIViewController.API_KEY)&symbols=\(item)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
			get(endPoint: UIViewController.GET_EXCHANGE_RATE+param) { (success, data) in
				if (success) {
					let apiData = data!
					self.otherRate = apiData["rates"]["\(item)"].doubleValue
					// EUR is default and only
					if (item != "EUR") {
						self.isOtherCurrency = true
					} else {
						self.isOtherCurrency = false
					}
				}
			}
		}
	}
	
	func setFlag(item: String, imageView: UIImageView) {
		switch item {
		// Set colors in place of flags for currencies with collective country usage
		case "XAF":
			// Central African CFA Franc
			imageView.backgroundColor = UIColor.red
			imageView.image = nil
		case "XCD":
			// Eastern Carribean Dollar
			imageView.backgroundColor = UIColor.blue
			imageView.image = nil
		case "XDR":
			// IMF Special Drawing Rights
			imageView.backgroundColor = UIColor.black
			imageView.image = nil
		case "XOF":
			// West African CFA Franc
			imageView.backgroundColor = UIColor.green
			imageView.image = nil
		case "XPF":
			// CFP Franc (Wallis & Futuna)
			imageView.image = Flag(countryCode: "WF")?.image(style: .circle)
		case "XAG":
			// Gold
			imageView.backgroundColor = UIColor.lightGray
			imageView.image = nil
		case "XAU":
			// Silver
			imageView.backgroundColor = UIColor.yellow
			imageView.image = nil
		default:
			// Get appropriate country flag
			let countryCode = String(item[...item.index(after: item.startIndex)])
			let flag = Flag(countryCode: countryCode)
			imageView.backgroundColor = nil
			imageView.image = flag!.image(style: .circle)
		}
	}
	
	// MARK: - DropDown Methods
	@objc func showExchangeCurrencyDropdown() {
		exchangeCurrencyDropDown.show()
	}
	
	@objc func showBaseCurrencyDropdown() {
		baseCurrencyDropDown.show()
	}
	
	@objc func endEditing() {
		view.endEditing(true)
	}
	
	/*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}
