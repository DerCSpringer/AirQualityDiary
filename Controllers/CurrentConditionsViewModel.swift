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
    
    private let diaryService : DiaryServiceType
    private let forecastFetcher: Observable<PollutionItem>
    private let currentFetcher: Observable<PollutionItem>
    private let api = AirNowAPI.instance



    
    private let sceneCoordinator: SceneCoordinatorType
    private let bag = DisposeBag()
    
    init(diaryService: DiaryServiceType, coordinator: SceneCoordinatorType) {
        self.diaryService = diaryService
        self.sceneCoordinator = coordinator
        
        //TODO: fix skipping 1 won't alway work and do it below and in AddDiaryEntryVM
        forecastFetcher = api.forecastConditions.asObservable().skip(1)
            .subscribeOn(MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .flatMap {json -> Observable<PollutionItem> in
                let pollutionItems : PollutionItem = try unbox(dictionary: json)
                return Observable.of(pollutionItems)
            }
            .shareReplay(1)
        
        currentFetcher = api.currentConditions.asObservable().skip(1)
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
        
        api.forecastFetchIsRunning.asObservable()
            .subscribeOn(MainScheduler.instance)
            .filter { $0 == true }
            .subscribe(onNext: { [weak self] _ in
                print("clearing")
                self?.clearUIForFetch()
            })
            .disposed(by: bag)
        
        api.currentFetchIsRunning.asObservable()
            .bind(to: currentFetchIsFetching)
            .disposed(by: bag)
        
        api.forecastFetchIsRunning.asObservable()
            .bind(to: forecastFetchIsFetching)
            .disposed(by: bag)

        bindOutput()
    }

    func onEntryButtonPress() -> CocoaAction {
        return CocoaAction { _ in
                    let diaryEntriesViewModel = DiaryEntriesViewModel(diaryService: self.diaryService, coordinator: self.sceneCoordinator)
                    return self.sceneCoordinator.transition(to: Scene.diaryEntries(diaryEntriesViewModel), type: .modal)
            }
        }
    
    private func bindOutput() {
        //TODO: below is very buggy
        //I think something is wrong with my implementation of bags and instances
        //If I make it public above then I can subscribe to variables and do work(clear ui)
        //If I make it private I can't do that but it isn't called twice
        //FIXED: Hmm looks like becuase I was setting a variable right away it was running the flatmap thing once then and once again when it was called.
        
//        let api = AirNowAPI()
        //Using an non-array for this right now
//        let forecastFetcher = self.forecastConditions.asObservable()
////            fetchOnEmit.flatMap { location, _ -> Observable<JSONObject> in
////            print(location)
////            return AirNowAPI.shared.searchForcastedAirQuality(latitude: location.latitude, longitude: location.longitude)
////            }
//            .subscribeOn(MainScheduler.instance)
//            .observeOn(MainScheduler.instance)
//            .flatMap {json -> Observable<PollutionItem> in
//                let pollutionItems : PollutionItem = try unbox(dictionary: json)
//                return Observable.of(pollutionItems)
//            }
//            .shareReplay(1)

//        fetchOnEmit
//            .subscribe(onNext:  { [weak self] _, _ in
//                self?.clearUIForFetch()
//            })
//        .disposed(by: bag)
        

        
//        fetchOnEmit
//            .map { _ in return true }
//        .bind(to: currentFetchIsFetching)
//        .disposed(by: bag)
//        
//        fetchOnEmit
//            .map { _ in return true }
//            .bind(to: forecastFetchIsFetching)
//            .disposed(by: bag)
        
//        let currentFetcher = fetchOnEmit.flatMap { location, _  -> Observable<[JSONObject]> in
//            return AirNowAPI.shared.searchAirQuality(latitude: location.latitude, longitude: location.longitude)
//            }
//            .observeOn(MainScheduler.instance)
//            .subscribeOn(MainScheduler.instance)
//            let currentFetcher = api.currentConditions
//                .observeOn(MainScheduler.instance)
//                .subscribeOn(MainScheduler.instance)
//            .flatMap {jsonArray -> Observable<[PollutionItem]> in
//                let pollutionItems : [PollutionItem] = try unbox(dictionaries: jsonArray)
//                return Observable.from(optional: pollutionItems)
//            }
//            .flatMap { pollutionItems -> Observable<PollutionItem> in
//                return Observable.from(pollutionItems)
//                
//            }
//            .shareReplay(1)
        

        
//        forecastFetcher
//            .map { _ in false }
//            .bind(to: forecastFetchIsFetching)
//            .disposed(by:bag)
        
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
//        .shareReplay(1)
        
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
