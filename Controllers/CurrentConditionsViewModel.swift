//
//  CurrentConditionsViewModel.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/30/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import CoreLocation

class CurrentConditionsViewModel {
    let tomorrowO3 = Variable<String>("Unavailable")
    let tomorrowPM = Variable<String>("Unavailable")
    let currentForcastPM = Variable<String>("Unavailable")
    let currentForcastO3 = Variable<String>("Unavailable")
    let currentO3 = Variable<String>("Unavailable")
    let currentPM = Variable<String>("Unavailable")
    
    private let locationManager = CLLocationManager()
    private let currentLocation : Observable<CLLocation>
    let bag = DisposeBag()
    
    init(coordinator: SceneCoordinatorType) {
        currentLocation = locationManager.rx.didUpdateLocations
            .map() { locations in
                //print(locations)
                return locations[0]
            }
            .filter() { location in
                return location.horizontalAccuracy <= kCLLocationAccuracyKilometer
        }
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        bindOutput()
    }
    
    func bindOutput() {
        
        let fetcher = currentLocation.take(1).flatMap() { location -> Observable<[AirNowAPI.JSONObject]> in
            print(location)
            return AirNowAPI.shared.searchAirQuality(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            .shareReplay(1)
        
        
        fetcher
            .filter
            .map {
                AirNowAPI.shared.formatJSON(jsonArray: $0)
        }
    }

    
//        forcast
//        .map {
//            AirNowAPI.shared.formatJSON(jsonArray: $0)
//        }
//        .map {
//            DiaryEntry(airQualityJSON: $0)
//        }
//        .addDiposeable(bag)

    
}
