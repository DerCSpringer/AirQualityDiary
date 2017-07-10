//
//  GeoLocationService.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 7/10/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

class GeolocationService {
    
    static let instance = GeolocationService()
    private (set) var authorized: Driver<Bool>
    private (set) var location: Driver<CLLocationCoordinate2D>
    
    private let locationManager = CLLocationManager()
    
    private init() {
        
        locationManager.distanceFilter = 5000
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        authorized = Observable.deferred { [weak locationManager] in
            let status = CLLocationManager.authorizationStatus()
            guard let locationManager = locationManager else {
                return Observable.just(status)
            }
            return locationManager
                .rx.didChangeAuthorizationStatus
                .startWith(status)
            }
            .asDriver(onErrorJustReturn: CLAuthorizationStatus.notDetermined)
            .map {
                switch $0 {
                case .authorizedAlways:
                    return true
                default:
                    return false
                }
        }
        
        location = locationManager.rx.didUpdateLocations
            .asDriver(onErrorJustReturn: [])
            .flatMap {
                return $0.last.map(Driver.just) ?? Driver.empty()
            }
            .filter {
                return ($0.timestamp.timeIntervalSinceNow < 300)
            }
            .map { $0.coordinate }
        
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
}
