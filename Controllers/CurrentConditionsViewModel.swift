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

typealias AQIAndLevel = (AQI: String, level: AirQualityLevel)
let defaultAQIAndLevel = AQIAndLevel("Unavailable", .unknown)

class CurrentConditionsViewModel {
    let forecastFetchIsFetching = Variable<Bool>(true)
    let currentFetchIsFetching = Variable<Bool>(true)
    let currentForecastO3 = Variable<AQIAndLevel>(defaultAQIAndLevel)
    let currentForcastPM = Variable<AQIAndLevel>(defaultAQIAndLevel)
    let tomorrowO3 = Variable<AQIAndLevel>(defaultAQIAndLevel)
    let currentO3 = Variable<AQIAndLevel>(defaultAQIAndLevel)
    let currentPM = Variable<AQIAndLevel>(defaultAQIAndLevel)
    let tomorrowPM = Variable<AQIAndLevel>(defaultAQIAndLevel)
    
    private var fetchOnEmit : Observable<(CLLocationCoordinate2D, Int)>
    private let currentLocation : Observable<CLLocationCoordinate2D>
    private let diaryService : DiaryServiceType
    
    private let sceneCoordinator: SceneCoordinatorType
    private let bag = DisposeBag()
    
    init(diaryService: DiaryServiceType, coordinator: SceneCoordinatorType) {
        self.diaryService = diaryService
        self.sceneCoordinator = coordinator
        
        currentLocation = GeolocationService.instance.location.asObservable()
            .distinctUntilChanged { loc1, loc2 in //prevents constant fetching in some instances
               return(loc1.latitude == loc2.latitude && loc1.longitude == loc2.longitude)
        }

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
    
    private func bindOutput() {
        //Using an non-array for this right now
        let forecastFetcher = fetchOnEmit.flatMap() { location, _ -> Observable<JSONObject> in
            print(location)
            return AirNowAPI.shared.searchForcastedAirQuality(latitude: location.latitude, longitude: location.longitude)
            }
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .flatMap {json -> Observable<PollutionItem> in
                let pollutionItems : PollutionItem = try unbox(dictionary: json)
                return Observable.of(pollutionItems)
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
            .flatMap {jsonArray -> Observable<[PollutionItem]> in

                let pollutionItems : [PollutionItem] = try unbox(dictionaries: jsonArray)
                return Observable.from(optional: pollutionItems)
            }
            .flatMap { pollutionItems -> Observable<PollutionItem> in
                return Observable.from(pollutionItems)
                
            }
            .shareReplay(1)
        
        currentFetcher
            .map { _ in false }
            .bind(to: currentFetchIsFetching)
            .disposed(by: bag)
        
        forecastFetcher
            .map { _ in false }
            .bind(to: forecastFetchIsFetching)
            .disposed(by:bag)
        
        //MARK: Current o3
        
        combineTitleAndPollutionTypeFor(currentFetcher, polluteName: .ozone)
            .bind(to: currentO3)
            .disposed(by: bag)

        //MARK: Current pm2.5
        
        combineTitleAndPollutionTypeFor(currentFetcher, polluteName: .PM2_5)
            .bind(to: currentPM)
            .disposed(by: bag)

        let todayForecast = forecastFetcher.filter { pollutionItem in
            pollutionItem.forecastFor == .today
        }
        let tomorrowForecast = forecastFetcher.filter { pollutionItem in
            pollutionItem.forecastFor == .tomorrow
        }
        
        //MARK: O3 for Tomorrow's Forecast
        
        combineTitleAndPollutionTypeFor(tomorrowForecast, polluteName: .ozone)
            .bind(to: tomorrowO3)
            .disposed(by: bag)
        
        //MARK: pm for Tomorrow's forecast
        
        combineTitleAndPollutionTypeFor(tomorrowForecast, polluteName: .PM2_5)
            .bind(to: tomorrowPM)
            .disposed(by: bag)
        
        //MARK: pm for Today's Forcast
        
        combineTitleAndPollutionTypeFor(todayForecast, polluteName: .PM2_5)
            .bind(to: currentForcastPM)
            .disposed(by: bag)
        
        //MARK: o3 for Today's Forcast
        
        combineTitleAndPollutionTypeFor(todayForecast, polluteName: .ozone)
        .bind(to: currentForecastO3)
        .disposed(by: bag)
    }
    
    private func combineTitleAndPollutionTypeFor(_ obs: Observable<PollutionItem>, polluteName:PollutantName) -> Observable<AQIAndLevel> {
        let pollute = obs.filter {
            $0.polluteName == polluteName
        }
        .shareReplay(1)
        
        let aqi = pollute.map {
            ($0.AQI == -1) ? "Unavailable" : String($0.AQI)
        }
        return Observable.combineLatest(aqi, pollute.flatMap{$0.pollutionType}){AQI, pollutionType in
            AQIAndLevel(AQI, pollutionType)
        }
    }
    private func clearUIForFetch() {
        //TODO: Delete following
        if Thread.isMainThread {
            print("On main thread")
        } else {
            print("On background thread")
        }
        currentO3.value = (defaultAQIAndLevel)
        currentPM.value = (defaultAQIAndLevel)
        tomorrowO3.value = (defaultAQIAndLevel)
        tomorrowPM.value = (defaultAQIAndLevel)
        currentForecastO3.value = (defaultAQIAndLevel)
        currentForcastPM.value = (defaultAQIAndLevel)
    }
}
