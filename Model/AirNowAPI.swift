//
//  AirNowAPI.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/19/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift

class AirNowAPI {
    
    static let shared = AirNowAPI()
    typealias  JSONObject = [String:Any]
    
    private let apiKey = "2758A15B-FD00-4191-AD80-11D2F8C73509"
    
    func searchAirQuality(latitude: Double, longitude: Double) -> Observable<[JSONObject]> {
        print("Calling API")

        let lat = String(latitude)
        let lon = String(longitude)

        let url = URL(string: "https://www.airnowapi.org/aq/observation/latLong/current/")!
        var request = URLRequest(url: url)
        let format = URLQueryItem(name: "format", value: "application/json")
        let keyQueryItem = URLQueryItem(name: "API_KEY", value: apiKey)
        let distQueryItem = URLQueryItem(name: "distance", value: String(25))
        let latQueryItem = URLQueryItem(name: "latitude", value: lat)
        let lonQueryItem = URLQueryItem(name: "longitude", value: lon)
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        urlComponents.queryItems = [format, latQueryItem, lonQueryItem, distQueryItem, keyQueryItem]
        
        request.url = urlComponents.url!
        request.httpMethod = "GET"
        
        //request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
    
    //http://www.airnowapi.org/aq/forecast/latLong/?format=text/csv&latitude=33.9681&longitude=-118.3444&date=2017-07-04&distance=25&API_KEY=2758A15B-FD00-4191-AD80-11D2F8C73509
    func searchForcastedAirQuality(latitude: Double, longitude: Double) -> Observable<JSONObject> {
        
        print("Calling API")
        let lat = String(latitude)
        let lon = String(longitude)
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        
        
        let url = URL(string: "https://www.airnowapi.org/aq/forecast/latLong/")!
        var request = URLRequest(url: url)
        let format = URLQueryItem(name: "format", value: "application/json")
        let date = URLQueryItem(name: "date", value: "\(dateFormat.string(from: Date()))")
        let keyQueryItem = URLQueryItem(name: "API_KEY", value: apiKey)
        let distQueryItem = URLQueryItem(name: "distance", value: String(25))
        let latQueryItem = URLQueryItem(name: "latitude", value: lat)
        let lonQueryItem = URLQueryItem(name: "longitude", value: lon)
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        urlComponents.queryItems = [format, latQueryItem, lonQueryItem, date, distQueryItem, keyQueryItem]
        
        request.url = urlComponents.url!
        request.httpMethod = "GET"
        
        
        return URLSession.shared.rx.json(request: request)
            .flatMap { response -> Observable<JSONObject> in
                guard let response = response as? Array<JSONObject> else {
                    return Observable.never()
                }
                return Observable.from(response.map { $0 })
        }
    }
}

extension AirNowAPI { //Garbage will fix once I figure out how to unbox array of items into single Model object
    func formatJSON(jsonArray: [JSONObject]) -> JSONObject {
        var o3 : Int?
        var pm25 : Int?
        var output : JSONObject = [:]
        for airQuality in jsonArray {
            if airQuality["ParameterName"] as? String == "O3" {o3 = airQuality["AQI"] as? Int }
            if airQuality["ParameterName"] as? String == "PM2.5" { pm25 = airQuality["AQI"] as? Int }
        }
        output["PM2.5"] = pm25
        output["O3"] = o3
        return output
    }
}
