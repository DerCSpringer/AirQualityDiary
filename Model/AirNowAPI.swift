//
//  AirNowAPI.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/19/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import Reachability
import CoreLocation

typealias JSONObject = [String:Any]

class AirNowAPI {
    
    private let bag = DisposeBag()
    
    let currentConditions =  Variable<[JSONObject]>([[:]])
    let forecastConditions = Variable<JSONObject>([:])
    let currentFetchIsRunning = Variable<Bool>(false)
    let forecastFetchIsRunning = Variable<Bool>(false)
    static let instance = AirNowAPI()
    
    private let geoLocation = GeolocationService.instance.location.asObservable()
        .distinctUntilChanged { loc1, loc2 in //prevents constant fetching in some instances
            return((loc1.latitude == loc2.latitude) && (loc1.longitude == loc2.longitude))
    }
    
    private init() {
        let api = AirNowAPICall()
        let reachabilityFetch = Observable.combineLatest(
            geoLocation,
            Observable<Int>.timer(1, period: 3600, scheduler: MainScheduler.instance),
            Reachability.rx.reachable,
            resultSelector: {location, _, reachable -> CLLocationCoordinate2D? in
                return reachable ? location : nil  //If it's not reachable it won't emit anything
        })
            .filter { $0 != nil }
            .map { $0! }
            .throttle(15, scheduler: MainScheduler.instance)

        
        reachabilityFetch.map {_ in return true }
            .bind(to: forecastFetchIsRunning)
            .disposed(by: bag)
        
        reachabilityFetch.map { _ in return true } //on update say it is fetching
        .bind(to: currentFetchIsRunning)
        .disposed(by: bag)
        
        reachabilityFetch
            .flatMap { api.getForecastedAirQuality(latitude: $0.latitude, longitude:$0.longitude) }
        .bind(to: forecastConditions)
            .disposed(by:bag)

        forecastConditions.asObservable().map { _ in return false }
            .bind(to: forecastFetchIsRunning)
            .disposed(by: bag)
        
        reachabilityFetch
        .flatMap { api.getCurrentAirQuality(latitude: $0.latitude, longitude:$0.longitude) }
        .bind(to: currentConditions)
        .disposed(by: bag)
        
        currentConditions.asObservable().map { _ in return false }
        .bind(to: currentFetchIsRunning)
        .disposed(by: bag)
    }

    
}

struct AirNowAPICall {
    
    private let apiKey = "2758A15B-FD00-4191-AD80-11D2F8C73509"

     fileprivate func getForecastedAirQuality(latitude: Double, longitude: Double) -> Observable<JSONObject> {
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
                if response.count != 0 {
                    return Observable.from(response.map { $0 })
                } else {
                    return Observable.just([:])
                }
        }
    }
    
    fileprivate func getCurrentAirQuality(latitude: Double, longitude: Double) -> Observable<[JSONObject]> {
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
        
        return URLSession.shared.rx.json(request: request).map { json in
            if let decodedJson = json as? [Any], let jsonObject = decodedJson as? [[String : Any]] {
                if jsonObject.count != 0 {
                    return jsonObject
                }
            }
            return []
        }

    }
}
