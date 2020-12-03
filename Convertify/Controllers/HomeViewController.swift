//
//  HomeViewController.swift
//  Convertify
//
//  Created by Nwachukwu Ejiofor on 29/11/2020.
//

import UIKit
import RealmSwift
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
	
	let realm = try! Realm()
	var baseValue = 0.0
	var exchangeValue = 0.0
	var time = ""
	var currencies = [String]()
	let baseCurrencyDropDown = DropDown()
	let exchangeCurrencyDropDown = DropDown()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		setupUI()
		disableConvert()
		infoLabel.isHidden = true
		infoBtn.isHidden = true
		getData { (err) in
			if err.isEmpty {
				// Setup currency dropdowns
				self.setupBaseCurrencyDropdown()
				self.setupExchangeCurrencyDropdown()
			} else {
				self.showToast(controller: self, message: "Error in getting rates. Please try again", seconds: 3.0)
			}
			self.removeSpinner()
		}
    }
    
	@IBAction func signUpBtnTapped(_ sender: UIButton) {
		// Segue to Sign Up page
	}
	
	@IBAction func infoBtnTapped(_ sender: UIButton) {
		// Show info alert
		let alert = UIAlertController(title: nil, message: "Rates are according to the latest mid-market values", preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		alert.addAction(okAction)
		present(alert, animated: true, completion: nil)
	}
	
	@IBAction func convertBtnTapped(_ sender: UIButton) {
		// Get base and exchange currency rates
		let baseCurrency = realm.objects(Currency.self).filter("name = '\(self.baseValueLabel.text!)'").first
		let exchangeCurrency = realm.objects(Currency.self).filter("name = '\(self.exchangeValueLabel.text!)'").first
		
		if let baseValue = Double(baseValueTextField.text!) {
			if let baseRate = baseCurrency?.rate {
				if let exchangeRate = exchangeCurrency?.rate {
					// Get exchange value for any 2 currencies conversion
					self.exchangeValue = baseValue * (exchangeRate / baseRate)
					// Display value to 6 d.p and change color of last 3 digits
					let exchangeValueText = String(format: "%.6f", self.exchangeValue)
					// Get index of number 3 digits after decimal point
					let index = (exchangeValueText.firstIndex(of: ".")?.utf16Offset(in: exchangeValueText))! + 4
					let attributedText = NSMutableAttributedString(string: exchangeValueText)
					attributedText.addAttribute(.foregroundColor, value: UIColor.lightGray, range: NSMakeRange(index, 3))
					self.exchangeValueTextField.attributedText = attributedText
					self.exchangeValueTextField.font = UIFont(name: "Helvetica", size: 24)
					
					self.infoLabel.text = "Mid-market exchange rate at \(self.time) UTC"
					self.infoLabel.isHidden = false
					self.infoBtn.isHidden = false
				}
			}
		} else {
			showToast(controller: self, message: "Enter valid number", seconds: 2.0)
		}
	}
	
	// MARK: TextField Delegate Methods
	@objc func textFieldDidChange(textField: UITextField) {
		exchangeValueTextField.text = ""
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
	
	func setupUI() {
		// Tap to dismiss keyboard
		let viewTap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
		view.addGestureRecognizer(viewTap)
		
		// Setup UI styling
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
		
		// Set default flags
		baseCurrencyImage.image = Flag(countryCode: "EU")?.image(style: .circle)
		exchangeCurrencyImage.image = Flag(countryCode: "US")?.image(style: .circle)
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
			setFlag(item: item, imageView: self.baseCurrencyImage)		}
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
			if let theFlag = flag {
				imageView.image = theFlag.image(style: .circle)
			}
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
	
	func getData(completion: @escaping (String) -> ()) {
		self.showSpinner()
		let param = "?access_key=\(UIViewController.API_KEY)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
		// Call 'latest' endpoint to get conversion rates
		get(endPoint: UIViewController.GET_EXCHANGE_RATE+param) { (success, data) in
			if (success) {
				let apiData = data!
				
				// Get UNIX timestamp and convert to UTC time
				let time = apiData["timestamp"].doubleValue
				let date = Date(timeIntervalSince1970: time)
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "HH:mm"
				dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
				let utcTime = dateFormatter.string(from: date)
				self.time = utcTime
				
				let latestRates = apiData["rates"].dictionaryObject
				self.realm.beginWrite()
				self.realm.delete(self.realm.objects(Currency.self))
				for (name, rate) in latestRates! {
					// Get names of currencies
					self.currencies.append(name)
					
					// Save each currency to RealmDB
					let currency = Currency()
					currency.name = name
					currency.rate = rate as! Double
					self.realm.add(currency)
				}
				try! self.realm.commitWrite()
				self.currencies.sort()
				
				DispatchQueue.main.async {
					completion("")
				}
			} else {
				DispatchQueue.main.async {
					completion("error")
				}
			}
		}
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
