//
//  ViewController.swift
//  Currency converter
//
//  Created by Alexander on 20/02/2017.
//  Copyright © 2017 Alexander Terekhov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var pickerFrom:UIPickerView!
    @IBOutlet weak var pickerTo:UIPickerView!
    @IBOutlet weak var activityIndicator:UIActivityIndicatorView!
    @IBOutlet weak var currencyCountField: UITextField!
    
    var currencies = ["RUB", "USD", "EUR"]
    let urlAdress = "https://api.fixer.io/latest?base="
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setup() {
        label.text = "No currency"
        pickerFrom.dataSource = self
        pickerTo.dataSource = self
        
        pickerFrom.delegate = self
        pickerTo.delegate = self
        currencyCountField.delegate = self
        
        activityIndicator.hidesWhenStopped = true
        requestCurrentCurrencyRate()
    }

    //MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return (pickerView == pickerTo) ?  self.currenciesExpectBase().count : currencies.count
    }

    //MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return (pickerView == pickerTo) ?  self.currenciesExpectBase()[row] : currencies[row]
    }
    
    //MARK: - Network
    
    func requestCurrencies(parseHandler:@escaping (Data?, Error?) -> Void) {
        let url = URL(string: urlAdress)!
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataRecieved, ressponse, error) in
            parseHandler(dataRecieved, error)
        }
        dataTask.resume()
    }
    
    func parseCurrenciesList(data: Data?, toCurrency: String) -> [String] {
        var value : [String] = []
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
           
        }catch {
        
        }
        
        return value
    }


    func requestCurrencyRates(baseCurrency: String, parseHandler:@escaping (Data?, Error?) -> Void) {
        let url = URL(string: urlAdress + baseCurrency)!
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataRecieved, ressponse, error) in
            parseHandler(dataRecieved, error)
        }
        dataTask.resume()
    }
    
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String {
        var value : String = ""
       
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            
            guard let parsedJSON = json else {
                value = "No JSON value parsed"
                return value
            }
            print("\(parsedJSON)")
            guard let rates = parsedJSON["rates"] as? Dictionary<String, Double> else {
                value = "No \"rates\" for currency found"
                return value
            }
            guard  let rate = rates[toCurrency] else {
               value = "No rate for currency \"\(toCurrency)\" found"
               return value
            }
            value = "\(rate)"
        }catch {
            value = error.localizedDescription
        }
        
        return value
    }
    
    func retrieveCurrencyRate(baseCurrency:String, toCurrency: String, completion: @escaping (String) -> Void) {
        self.requestCurrencyRates(baseCurrency: baseCurrency) {
            [weak self] (data, error) in
            var string = "No currency retrieved!"
            if let currentError = error {
                string = currentError.localizedDescription
            } else if let strongSelf = self {
                string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
            }
            completion(string)
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        return  (pickerView == pickerFrom) ?  self.pickerTo.reloadAllComponents() : self.requestCurrentCurrencyRate()
    }
    
    func requestCurrentCurrencyRate() {
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExpectBase()[toCurrencyIndex]
        
        self.retrieveCurrencyRate(baseCurrency:baseCurrency, toCurrency: toCurrency) {
            [weak self] (value) in
            DispatchQueue.main.async(execute: {
                if let strongSelf = self {
                    strongSelf.label.text = value
                    strongSelf.activityIndicator.stopAnimating()
                }
            })
        }
    }
    
    func currenciesExpectBase() -> [String] {
        var currenciesExpectBase = currencies
        currenciesExpectBase.remove(at: pickerFrom.selectedRow(inComponent: 0))
        
        return currenciesExpectBase
    }
}
