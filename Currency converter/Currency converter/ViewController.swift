//
//  ViewController.swift
//  Currency converter
//
//  Created by Alexander on 22/02/2017.
//  Copyright © 2017 Alexander Terekhov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var pickerFrom:UIPickerView!
    @IBOutlet weak var pickerTo:UIPickerView!
    @IBOutlet weak var activityIndicator:UIActivityIndicatorView!
    @IBOutlet weak var currencyCountField: UITextField!
    @IBOutlet weak var generalActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var overlay: UIView!
    
    fileprivate var currencies = [String]()
    fileprivate let api = API()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    fileprivate func setup() {
        generalActivityIndicator.startAnimating()
        
        pickerFrom.dataSource = self
        pickerTo.dataSource = self
        
        pickerFrom.delegate = self
        pickerTo.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        api.requestCurrencies {
            maybeCurrencies, maybeError in
            
            DispatchQueue.main.async {
                self.overlay.isHidden = true
                self.generalActivityIndicator.stopAnimating()
                
                if let currencies = maybeCurrencies {
                    self.currencies.append(contentsOf: currencies)
                    self.reload()
                }
                else if let error = maybeError {
                    self.handle(error: error)
                }
                else {
                    self.handleUnknownError()
                }
            }
        }
    
        currencyCountField.addTarget(self,
                                     action: #selector(calculate),
                                     for: .editingChanged)
    }
    
    fileprivate func reload() {
        pickerFrom.reloadAllComponents()
        pickerTo.reloadAllComponents()
        calculate()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       currencyCountField.resignFirstResponder()
    }

    @objc fileprivate func calculate() {
        showCalculationIndicator()
        self.retrieveCurrencyRate(baseCurrency:detectBaseCurrency(), toCurrency: detectToCurrency()) {
            rate in

            self.calculateAmount(rate: rate)
            self.activityIndicator.stopAnimating()
        }
    }
    
    fileprivate func showCalculationIndicator() {
        self.label.text = ""
        self.activityIndicator.startAnimating()
    }
    
    fileprivate func calculateAmount(rate: Double) {
        guard let amountText = currencyCountField.text,
            let baseCurrencyAmount = Double(amountText) else {
            label.text = "Invalid amount specified"
            return
        }
        
        let convertedAmount = baseCurrencyAmount * rate
        self.label.text = "\(convertedAmount)"
    }
    
    fileprivate func detectBaseCurrency() -> String {
        return currencies[pickerFrom.selectedRow(inComponent: 0)]
    }
    
    fileprivate func detectToCurrency() -> String {
        return currencies[pickerTo.selectedRow(inComponent: 0)]
    }

    fileprivate func retrieveCurrencyRate(baseCurrency:String,
                                          toCurrency: String,
                                          completion: @escaping (Double) -> Void) {
        api.requestRate(baseCurrency: baseCurrency, toCurrency: toCurrency) {
            rate, maybeError in
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                if rate > 0 {
                    completion(rate)
                }
                else if let error = maybeError {
                    self.handle(error: error)
                }
                else {
                    self.handleUnknownError()
                }
            }
        }
    }
    
    fileprivate func handle(error: Error) {
        if let apiError = error as? APIError {
            handle(apiError: apiError)
        }
        else {
            handle(generalError: error)
        }
    }
    
    fileprivate func handle(apiError: APIError) {
        switch apiError {
        case .emptyResponse, .invalidResponse, .noData: showAlert(title: "Error", message: "Something is wrong with our data. Please, check your connection and try again")
        case .noRateFound: label.text = "No rate found"
        }
    }
    
    fileprivate func handle(generalError: Error) {
        showAlert(title: "Error", message: "Something went wrong. Please, check your connection and try again")
    }
    
    fileprivate func handleUnknownError() {
        showAlert(title: "Error", message: "Something went wrong. Please, check your connection and try again")
    }
    
    fileprivate func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
        present(alertController, animated: true)
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currencies.count
    }

    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        return calculate()
    }
}
