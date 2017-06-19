//
//  BreezoMeterAPI.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/19/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift

class ApiController {
    
    static let shared = ApiController()
    typealias  JSONObject = [String:Any]
    
    private let apiKey = "20198f262f8a411f844a06804645cc39"
    
    func searchAirQuality(latitude: String, longitute: String) -> Observable<JSONObject> {
        let url = URL(string: "https://api.breezometer.com/baqi")!
        var request = URLRequest(url: url)
        let keyQueryItem = URLQueryItem(name: "api_key", value: apiKey)
        let latQueryItem = URLQueryItem(name: "lat", value: latitude)
        let lonQueryItem = URLQueryItem(name: "lon", value: longitute)
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        urlComponents.queryItems = [latQueryItem, lonQueryItem, keyQueryItem]
        
        request.url = urlComponents.url!
        request.httpMethod = "GET"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.rx.json(request: request).map { json in
            if let jsonObj = json as? [String:Any] {
                return jsonObj
            } else {
                return [:]
            }
    }
}
}
