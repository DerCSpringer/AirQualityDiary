//
//  BreezoMeterAPI.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/19/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift

class BreezoMeterAPI {
    
    static let shared = BreezoMeterAPI()
    typealias  JSONObject = [String:Any]
    
    private let apiKey = "2758A15B-FD00-4191-AD80-11D2F8C73509"
    
    func searchAirQuality(latitude: Double, longitude: Double) -> Observable<[JSONObject]> {
        let lat = String(latitude)
        let lon = String(longitude)

        let url = URL(string: "https://www.airnowapi.org/aq/observation/latLong/current/")!
        var request = URLRequest(url: url)
        //?format=application/
        let format = URLQueryItem(name: "format", value: "application/json")
        let keyQueryItem = URLQueryItem(name: "API_KEY", value: apiKey)
        let distQueryItem = URLQueryItem(name: "distance", value: String(25))
        let latQueryItem = URLQueryItem(name: "latitude", value: lat)
        let lonQueryItem = URLQueryItem(name: "longitude", value: lon)
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        urlComponents.queryItems = [format, latQueryItem, lonQueryItem, distQueryItem, keyQueryItem]
        
        request.url = urlComponents.url!
        request.httpMethod = "GET"
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.rx.json(request: request).map { json in
            if let a = json as? [Any], let b = a as? [[String : Any]] {
                return b
            }
            return []
        }
        
//            { json in //map each json emit to an array
//            if let a = json as? [String:Any] {
//            return a
//            }
 //       }
//        if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? T, let result = json {
//            observer.onNext(result)
//        }
//        observer.onCompleted()
 //   }

//        return URLSession.shared.rx.json(request: request).map { json in
//            if let jsonObj = json as? [String:Any] {
//                return jsonObj
//            } else {
//                return [:]
//            }
//    }
}
}

extension BreezoMeterAPI { //Garbage will fix once I figure out how to unbox array of items into single Model object
    func formatJSON(jsonArray: [JSONObject]) -> JSONObject {
        var o3 : Float?
        var pm25 : Float?
        var output : JSONObject = [:]
        for airQuality in jsonArray {
            if airQuality["ParameterName"] as? String == "O3" {o3 = airQuality["AQI"] as? Float }
            if airQuality["ParameterName"] as? String == "PM2.5" { pm25 = airQuality["AQI"] as? Float }
        }
        output["PM2.5"] = pm25
        output["O3"] = o3
        return output
    }
}
