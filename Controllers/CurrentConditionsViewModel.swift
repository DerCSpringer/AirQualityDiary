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
import Unbox

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
        //NEED to add a geo service later
        

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
        
        //Issue here is that I'm using JSON where I should use model objects
        //JSON should be all decoded earlier
        //I'm thinking use one object for searchAirQuality and another for searchForactedAirQuality
        //They both share o3 and pm25, but forcasted has two pm25s and two o3s each with different values
        //searchairqualyt is abl to decode to a diaryEntry, which is useful but it's not really a diary entry
//        
//        let forecastFetcher = fetchOnEmit.flatMap() { location, _ -> Observable<JSONObject> in
//            print(location)
//            return AirNowAPI.shared.searchForcastedAirQuality(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//            }
//            .shareReplay(1)
        
        let forecastFetcher = fetchOnEmit.flatMap() { location, _ -> Observable<[JSONObject]> in
            print(location)
            return AirNowAPI.shared.searchForcastedAirQuality2(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
            .flatMap { jsonArray -> Observable<[PolutionItem]> in
                let polutionItems : [PolutionItem] = try unbox(dictionaries: jsonArray)
                print("polution items: \(polutionItems)")
                //return polutionItems.map(Observable.just)
                return Observable.of(polutionItems)
            }
            .flatMap { polutionItems -> Observable<PolutionItem> in
                return Observable.from(polutionItems)
            }
            .shareReplay(1)
        
        let currentFetcher = fetchOnEmit.flatMap { location, _ -> Observable<[JSONObject]> in
            return AirNowAPI.shared.searchAirQuality(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
                .map {
                    AirNowAPI.shared.formatJSON(jsonArray: $0)
                }
            .map {
                DiaryEntry(airQualityJSON: $0)
            }
                .shareReplay(1)
        
        
        currentFetcher.map { String($0.o3) }
            .bind(to: currentO3)
            .disposed(by: bag)
        
        currentFetcher.map { String($0.pm25) }
            .bind(to: currentPM)
            .disposed(by: bag)
        
        //these filter for which forcast day using json
//        let todayForecast = forecastFetcher.filter { [weak self] dict in //should be done in airnowapi
//            let date = dict["DateForecast"] as! String
//            return date == self!.dateFormat.string(from: Date())
//        }
        
        let todayForecast = forecastFetcher.filter { polutionItem in
            return polutionItem.forecastFor == .today
        }
        let tomorrowForecast = forecastFetcher.filter { polutionItem in
            return polutionItem.forecastFor == .tomorrow
        }

//
//        let tomorrowForecast = forecastFetcher.filter { [weak self] dict in
//            let date = dict["DateForecast"] as! String
//            return date != self!.dateFormat.string(from: Date())
//        }
        
        
    
        tomorrowForecast.filter { polutionItem in
            polutionItem.polututeName == .ozone
            }
            .map { polutionItem in
                return String(describing: polutionItem.AQI)
            }
            .bind(to: tomorrowO3)
            .disposed(by: bag)
        
        tomorrowForecast.filter { polutionItem in
            polutionItem.polututeName == .PM2_5
            }
            .map { polutionItem in
                return String(describing: polutionItem.AQI)
            }
            .bind(to: tomorrowPM)
            .disposed(by: bag)
        
        todayForecast.filter { polutionItem in
            polutionItem.polututeName == .ozone
            }
            .map { polutionItem in
                return String(describing: polutionItem.AQI)
            }
            .bind(to: currentForcastO3)
            .disposed(by: bag)
        
        todayForecast.filter { polutionItem in
            polutionItem.polututeName == .PM2_5
            }
            .map { polutionItem in
                return String(describing: polutionItem.AQI)
            }
            .bind(to: currentForcastPM)
            .disposed(by: bag)
    }
}
