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
import Action

class CurrentConditionsViewModel {
    let tomorrowO3 = Variable<String>("Unavailable")
    let tomorrowPM = Variable<String>("Unavailable")
    let currentForcastPM = Variable<String>("Unavailable")
    let currentForcastO3 = Variable<String>("Unavailable")
    let currentO3 = Variable<String>("Unavailable")
    let currentPM = Variable<String>("Unavailable")
    let dateFormat = DateFormatter()
    
    private let locationManager = CLLocationManager()
    private var fetchOnEmit : Observable<(CLLocation, Int)>
    private let currentLocation : Observable<CLLocation>
    private let diaryService : DiaryServiceType
    let sceneCoordinator: SceneCoordinatorType
    let bag = DisposeBag()
    
    init(diaryService: DiaryServiceType, coordinator: SceneCoordinatorType) {
        self.diaryService = diaryService
        self.sceneCoordinator = coordinator
        dateFormat.dateFormat = "yyyy-MM-dd "//space must be here b/c bad formatted JSON
        
        locationManager.distanceFilter = 5000
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        
        //Filters for accuracy and makes sure a new location value is selected
        currentLocation = locationManager.rx.didUpdateLocations
            .flatMap {
                return $0.last.map(Observable.just) ?? Observable.empty()
        }
            .filter {
                return $0.horizontalAccuracy <= kCLLocationAccuracyKilometer
        }
            .filter {
                return ($0.timestamp.timeIntervalSinceNow < 300)
        }
        
    
        let hourTimer = Observable<Int>
            .timer(1, period: 3600, scheduler: MainScheduler.instance)

        fetchOnEmit = Observable.combineLatest(currentLocation, hourTimer)
        { ($0,$1) }


        
        
        //below methods are only called on init.  They must be called on each time we load the controller or maybe every x amount of time.
        //We don't update our current location unless we've changed and we're 5 kilometers away from our recorded location
        //I think I'll make a class which is our location class.  
        //the class will check our current location and if we're greater than 5 kilos it emits our new location
        //this calls for an update(maybe only if we're the front app though or this screen is showing
        //another class will be our fetching class
        //It will check the plist and call a fetch or use cahced data
        //It should have a running variable to say it's running
        //it should recieve and enum indicating if it wants the full forcast or just current conditions
        //don't need to worry about fetching all the time in adddiaryentry which would prevent a fetch in the forecast
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        bindOutput()
    }

    func onEntryButtonPress() -> CocoaAction {
        return CocoaAction { _ in
                    let diaryEntriesViewModel = DiaryEntriesViewModel(diaryService: self.diaryService, coordinator: self.sceneCoordinator)
                    return self.sceneCoordinator.transition(to: Scene.diaryEntries(diaryEntriesViewModel), type: .modal)
            }
        }
    
    func bindOutput() {
        
        let forecastFetcher = fetchOnEmit.flatMap() { location, _ -> Observable<JSONObject> in
            print(location)
            return AirNowAPI.shared.searchForcastedAirQuality(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            .shareReplay(1)
        
        
        let todayForecast = forecastFetcher.filter { [weak self] dict in
            let date = dict["DateForecast"] as! String
            return date == self!.dateFormat.string(from: Date())
        }
        
        let tomorrowForecast = forecastFetcher.filter { [weak self] dict in
            let date = dict["DateForecast"] as! String
            return date != self!.dateFormat.string(from: Date())
        }
        
        //fix casting
        tomorrowForecast.filter { dict in
            return dict["ParameterName"] as! String == "O3"
            }
            .map { dict in
                return String(describing: dict["AQI"]!)
            }
            .bind(to: tomorrowO3)
            .disposed(by: bag)
        
        tomorrowForecast.filter { dict in
            return dict["ParameterName"] as! String == "PM2.5"
            }
            .map { dict in
                return String(describing: dict["AQI"]!)
            }
            .bind(to: tomorrowPM)
            .disposed(by: bag)
        
        todayForecast.filter { dict in
            return dict["ParameterName"] as! String == "O3"
            }
            .map { dict in
                return String(describing: dict["AQI"]!)
            }
            .bind(to: currentForcastO3)
            .disposed(by: bag)
        
        todayForecast.filter { dict in
            return dict["ParameterName"] as! String == "PM2.5"
            }
            .map { dict in
                return String(describing: dict["AQI"]!)
            }
            .bind(to: currentForcastPM)
            .disposed(by: bag)
    }
}



