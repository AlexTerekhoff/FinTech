//
//  API.swift
//  Currency converter
//
//  Created by Alexander Terekhov on 22/02/2017.
//  Copyright © 2017 Alexander Terekhov. All rights reserved.
//

import Foundation

enum APIError: Error {
    case noData
    case invalidResponse
    case emptyResponse
    case noRateFound
}

final class API {
    fileprivate let urlAdress = "https://api.fixer.io/latest"
    
    func requestCurrencies(completionHandler: @escaping ([String]?, Error?) -> Void) {
        let url = URL(string: urlAdress)!
        let dataTask = URLSession.shared.dataTask(with: url) {
            (maybeData, ressponse, error) in
            do {
                guard let data = maybeData else {
                    completionHandler(nil, APIError.noData)
                    return
                }
                
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completionHandler(nil, APIError.invalidResponse)
                    return
                }
                
                print("\(json)")
                guard let rates = json["rates"] as? [String: Any] else {
                    completionHandler(nil, APIError.emptyResponse)
                    return
                }
                
                var currencies = Array(rates.keys)
                if let baseCurrency = json["base"] as? String {
                    currencies.append(baseCurrency)
                }
                
                completionHandler(currencies, nil)
            }
            catch {
                completionHandler(nil, error)
            }
        }
        
        dataTask.resume()
    }
    
    func requestRate(baseCurrency: String,
                     toCurrency: String,
                     completionHandler: @escaping (Double, Error?) -> Void) {
        do {
            let rate = try self.getRateFromCache(from: baseCurrency, to: toCurrency)
            completionHandler(rate, nil)
        }
        catch {
            getRateFromApi(baseCurrency: baseCurrency,
                           toCurrency: toCurrency,
                           completionHandler: completionHandler)
        }
    }
    
    fileprivate func getRateFromApi(baseCurrency: String,
                                    toCurrency: String,
                                    completionHandler: @escaping (Double, Error?) -> Void) {
        let url = URL(string: urlAdress + "?base=" + baseCurrency)!
        let dataTask = URLSession.shared.dataTask(with: url) {
            data, response, error in
            
            do {
                try self.cacheCurrencyRatesResponse(data, forCurrency: baseCurrency)
                let rate = try self.getRateFromCache(from: baseCurrency, to: toCurrency)
                completionHandler(rate, nil)
            }
            catch {
                completionHandler(0, error)
            }
        }
        
        dataTask.resume()
    }
    
    fileprivate var ratesCache = [String: [String: Double]]()
    
    fileprivate func cacheCurrencyRatesResponse(_ maybeData: Data?, forCurrency currency: String) throws -> Void {
        guard let data = maybeData else { throw APIError.noData }
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let parsedJSON = json else { throw APIError.invalidResponse }
        print("\(parsedJSON)")
        guard let rates = parsedJSON["rates"] as? [String: Double] else { throw APIError.emptyResponse }
        ratesCache[currency] = rates
    }
    
    fileprivate func getRateFromCache(from: String, to: String) throws -> Double {
        guard let rates = ratesCache[from] else { throw APIError.noRateFound }
        guard let rate = rates[to] else { throw APIError.noRateFound }
        return rate
    }

}
