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
import UIKit

//I should send a model object
//The VC then sends off the quality to get the color
//It uses the color and the text to make the label
//Maybe I should just pass along the polution type(Observable) and the VC can then handle the color and text
class CurrentConditionsViewModel {
    typealias AQIAndLevel = (AQI: String, level: AirQualityLevel)
    private static let defaultValue = AQIAndLevel("Unavailable", .unknown)
    let forecastFetchIsFetching = Variable<Bool>(true)
    let currentFetchIsFetching = Variable<Bool>(true)
    let currentForecastO3 = Variable<AQIAndLevel>(defaultValue)
    let currentForcastPM = Variable<AQIAndLevel>(defaultValue)
    let tomorrowO3 = Variable<AQIAndLevel>(defaultValue)
    let currentO3 = Variable<AQIAndLevel>(defaultValue)
    let currentPM = Variable<AQIAndLevel>(defaultValue)
    let tomorrowPM = Variable<AQIAndLevel>(defaultValue)
    
    private var fetchOnEmit : Observable<(CLLocationCoordinate2D, Int)>
    private let currentLocation : Observable<CLLocationCoordinate2D>
    private let diaryService : DiaryServiceType
    
    private let badConditionColor = #colorLiteral(red: 1, green: 0.3244201541, blue: 0, alpha: 1)
    private let cautionConditionColor = #colorLiteral(red: 0.9828135371, green: 1, blue: 0, alpha: 1)
    private let goodConditionColor = #colorLiteral(red: 0.1539898217, green: 1, blue: 0, alpha: 1)
    
    let sceneCoordinator: SceneCoordinatorType
    private let bag = DisposeBag()
    
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
                self?.clearUIForFetch()
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
        
        //MARK: Current o3
        let o3Current = currentFetcher
            .observeOn(MainScheduler.instance)
            .filter {
            $0.polututeName == .ozone
            }
            .shareReplay(1)
        
        let o3AQICurrent =  o3Current.map {
            ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
        }
        
        Observable.combineLatest(o3AQICurrent, o3Current.flatMap{$0.polutionType}){AQI, polutionType in
            return (AQIAndLevel(AQI, polutionType))
            }
            .bind(to: currentO3)
            .disposed(by: bag)

        //MARK: Current pm2.5
        let pmCurrent = currentFetcher.filter {
            $0.polututeName == .PM2_5
            }
            .shareReplay(1)
        
        let pmAQICurrent =  pmCurrent.map {
            ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
        }
        
        Observable.combineLatest(pmAQICurrent, pmCurrent.flatMap{$0.polutionType}){AQI, polutionType in
            return (AQIAndLevel(AQI, polutionType))
            }
            .bind(to: currentPM)
            .disposed(by: bag)

        
        let todayForecast = forecastFetcher.filter { polutionItem in
            return polutionItem.forecastFor == .today
        }
        let tomorrowForecast = forecastFetcher.filter { polutionItem in
            return polutionItem.forecastFor == .tomorrow
        }
        
        //MARK: O3 for Tomorrow's Forecast

        let o3TomorrowForecast = tomorrowForecast
            .filter {
            return $0.polututeName == .ozone
            }
            .shareReplay(1)
        
        
        let o3AQITomorrowForecast =  o3TomorrowForecast.map {
            ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
        }
        
        Observable.combineLatest(o3AQITomorrowForecast, o3TomorrowForecast.flatMap{$0.polutionType}){AQI, polutionType in
            return (AQIAndLevel(AQI, polutionType))
            }
            .bind(to: tomorrowO3)
            .disposed(by: bag)
        
        //MARK: pm for Tomorrow's forecast
        
        let pmTomorrowForecast = tomorrowForecast.filter { polutionItem in
            polutionItem.polututeName == .PM2_5
            }
        .shareReplay(1)
        
        let pmAQITomorrowForecast =  pmTomorrowForecast.map {
            ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
        }
        
        Observable.combineLatest(pmAQITomorrowForecast, pmTomorrowForecast.flatMap{$0.polutionType}){AQI, polutionType in
            return (AQIAndLevel(AQI, polutionType))
            }
            .bind(to: currentForcastPM)
            .disposed(by: bag)
        
        //MARK: pm for Today's Forcast
        
        let pmTodayForecast = todayForecast
            .filter {
                $0.polututeName == .PM2_5
            }
            .shareReplay(1)
        
        let pmAQITodayForecast =  pmTodayForecast.map {
            ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
        }
        
        Observable.combineLatest(pmAQITodayForecast, pmTodayForecast.flatMap{$0.polutionType}){AQI, polutionType in
            return (AQIAndLevel(AQI, polutionType))
            }
            .bind(to: currentForcastPM)
            .disposed(by: bag)
        
        //MARK: o3 for Today's Forcast
        
        let o3TodayForecast = todayForecast
            .filter {
                $0.polututeName == .ozone
        }
        .shareReplay(1)
        
        let o3AQITodayForecast =  o3TodayForecast.map {
                ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
        }

        Observable.combineLatest(o3AQITodayForecast, o3TodayForecast.flatMap{$0.polutionType}){AQI, polutionType in
            return (AQIAndLevel(AQI, polutionType))
        }
        .bind(to: currentForecastO3)
        .disposed(by: bag)

    }
    func clearUIForFetch() {
        if Thread.isMainThread {
            print("On main thread")
        } else {
            print("On background thread")
        }
        
        currentO3.value = ("Unavailable", .unknown)
        currentPM.value = ("Unavailable", .unknown)
        tomorrowO3.value = ("Unavailable", .unknown)
        tomorrowPM.value = ("Unavailable", .unknown)
        currentForecastO3.value = ("Unavailable", .unknown)
        currentForcastPM.value = ("Unavailable", .unknown)
    }
}
