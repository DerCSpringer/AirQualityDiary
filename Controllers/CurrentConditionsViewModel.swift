//
//  CurrentConditionsViewModel.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/30/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
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
    let forecastFetchIsFetching = Variable<Bool>(true)
    let currentFetchIsFetching = Variable<Bool>(true)

    
    private var fetchOnEmit : Observable<(CLLocationCoordinate2D, Int)>
    private let currentLocation : Observable<CLLocationCoordinate2D>
    private let diaryService : DiaryServiceType
    
    private let badConditionColor = #colorLiteral(red: 1, green: 0.3244201541, blue: 0, alpha: 1)
    private let cautionConditionColor = #colorLiteral(red: 0.9828135371, green: 1, blue: 0, alpha: 1)
    private let goodConditionColor = #colorLiteral(red: 0.1539898217, green: 1, blue: 0, alpha: 1)
    
    let sceneCoordinator: SceneCoordinatorType
    let bag = DisposeBag()
    
    init(diaryService: DiaryServiceType, coordinator: SceneCoordinatorType) {
        self.diaryService = diaryService
        self.sceneCoordinator = coordinator

        
        currentLocation = GeolocationService.instance.location.asObservable()
            .distinctUntilChanged { loc1, loc2 in //prevents constant fetching in some instances
               return(loc1.latitude == loc2.latitude && loc1.longitude == loc2.longitude)
        }
        //Filters for accuracy and makes sure a new location value is selected
//        currentLocation = location
//            .flatMap {
//                return $0.last.map(Observable.just) ?? Observable.empty()
//        }
//            .filter {
//                return $0.horizontalAccuracy <= kCLLocationAccuracyKilometer
//        }

        let hourTimer = Observable<Int>
            .timer(1, period: 3600, scheduler: MainScheduler.instance)

        fetchOnEmit = Observable.combineLatest(currentLocation, hourTimer)
        { ($0,$1) }
        .throttle(5, scheduler: MainScheduler.instance) //Just in case it decides to query very quickly

        bindOutput()
    }

    func onEntryButtonPress() -> CocoaAction {
        return CocoaAction { _ in
                    let diaryEntriesViewModel = DiaryEntriesViewModel(diaryService: self.diaryService, coordinator: self.sceneCoordinator)
                    return self.sceneCoordinator.transition(to: Scene.diaryEntries(diaryEntriesViewModel), type: .modal)
            }
        }
    
    func bindOutput() {
        //Using an non-array for this right now
        let forecastFetcher = fetchOnEmit.flatMap() { location, _ -> Observable<JSONObject> in
            print(location)
            return AirNowAPI.shared.searchForcastedAirQuality(latitude: location.latitude, longitude: location.longitude)
            }
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .flatMap {json -> Observable<PolutionItem> in
                let polutionItems : PolutionItem = try unbox(dictionary: json)
                return Observable.of(polutionItems)
            }
            .shareReplay(1)

        fetchOnEmit
            .subscribe(onNext:  { [weak self] _, _ in
                self?.updateUIForFetch()
            })
        .disposed(by: bag)
        
        fetchOnEmit
            .map { _ in return true }
        .bind(to: currentFetchIsFetching)
        .disposed(by: bag)
        
        fetchOnEmit
            .map { _ in return true }
            .bind(to: forecastFetchIsFetching)
            .disposed(by: bag)
        
        //Something to consider is the sorting of items and picking a smallest value which you're suseptible too
        //-1 will mess this up.
        
        //-1 still displays sometimes in UI. I need to fix this
        //Looks like clearValues() is not being executed on the main thread.  May need to think where I place it
        
        let currentFetcher = fetchOnEmit.flatMap { location, _  -> Observable<[JSONObject]> in
            return AirNowAPI.shared.searchAirQuality(latitude: location.latitude, longitude: location.longitude)
            }
            .observeOn(MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .flatMap {jsonArray -> Observable<[PolutionItem]> in

                let polutionItems : [PolutionItem] = try unbox(dictionaries: jsonArray)
                return Observable.from(optional: polutionItems)
            }
            .flatMap { polutionItems -> Observable<PolutionItem> in
                return Observable.from(polutionItems)
                
            }
            .shareReplay(1)
        
        currentFetcher
            .map { _ in return false }
            .bind(to: currentFetchIsFetching)
            .disposed(by: bag)
        
        forecastFetcher
            .map { _ in false }
            .bind(to: forecastFetchIsFetching)
            .disposed(by:bag)
        
        currentFetcher
            .observeOn(MainScheduler.instance)
            .filter {
            return $0.polututeName == .ozone
            }
            .map {
                ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
            }
            .bind(to: currentO3)
            .disposed(by: bag)
        
        currentFetcher.filter {
            return $0.polututeName == .PM2_5
            }
            .map {
                ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
            }
            .bind(to: currentPM)
            .disposed(by: bag)
        
        let todayForecast = forecastFetcher.filter { polutionItem in
            return polutionItem.forecastFor == .today
        }
        let tomorrowForecast = forecastFetcher.filter { polutionItem in
            return polutionItem.forecastFor == .tomorrow
        }

        tomorrowForecast
            .filter {
            return $0.polututeName == .ozone
            }
            .map {
                return ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
            }
            .bind(to: tomorrowO3)
            .disposed(by: bag)
        
        tomorrowForecast.filter { polutionItem in
            polutionItem.polututeName == .PM2_5
            }
            .map {
                ($0.AQI == -1) ? "Unavailable" : String($0.AQI)

            }
            .bind(to: tomorrowPM)
            .disposed(by: bag)
        
        todayForecast.filter { polutionItem in
            polutionItem.polututeName == .ozone
            }
            .map {
                ($0.AQI == -1) ? "Unavailable" : String($0.AQI)

            }
            .bind(to: currentForcastO3)
            .disposed(by: bag)
        
        todayForecast.filter { polutionItem in
            polutionItem.polututeName == .PM2_5
            }
            .map {
                ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
            }
            .bind(to: currentForcastPM)
            .disposed(by: bag)
    }
    
    func updateUIForFetch() {
        if Thread.isMainThread {
            print("On main thread")
        } else {
            print("On background thread")
        }
        
        currentO3.value = "Unavailable"
        currentPM.value = "Unavailable"
        tomorrowO3.value = "Unavailable"
        tomorrowPM.value = "Unavailable"
        currentForcastO3.value = "Unavailable"
        currentForcastPM.value = "Unavailable"
    }
}
