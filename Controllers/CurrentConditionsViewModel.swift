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
    let currentForecastPM = Variable<AQIAndLevel>(defaultAQIAndLevel)
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
        
        //MARK: Current o3
        
        PollutionLevel.combineTitleAndPollutionTypeFor(currentFetcher, polluteName: .ozone)
            .bind(to: currentO3)
            .disposed(by: bag)

        //MARK: Current pm2.5
        
        PollutionLevel.combineTitleAndPollutionTypeFor(currentFetcher, polluteName: .PM2_5)
            .bind(to: currentPM)
            .disposed(by: bag)

        let todayForecast = forecastFetcher.filter { pollutionItem in
            pollutionItem.forecastFor == .today
        }
        let tomorrowForecast = forecastFetcher.filter { pollutionItem in
            pollutionItem.forecastFor == .tomorrow
        }
        
        //MARK: O3 for Tomorrow's Forecast
        
        
        PollutionLevel.combineTitleAndPollutionTypeFor(tomorrowForecast, polluteName: .ozone)
            .bind(to: tomorrowO3)
            .disposed(by: bag)
        
        //MARK: pm for Tomorrow's forecast
        
        PollutionLevel.combineTitleAndPollutionTypeFor(tomorrowForecast, polluteName: .PM2_5)
            .bind(to: tomorrowPM)
            .disposed(by: bag)
        
        //MARK: pm for Today's Forecast
        
        PollutionLevel.combineTitleAndPollutionTypeFor(todayForecast, polluteName: .PM2_5)
            .bind(to: currentForecastPM)
            .disposed(by: bag)
        
        //MARK: o3 for Today's Forecast
        
        PollutionLevel.combineTitleAndPollutionTypeFor(todayForecast, polluteName: .ozone)
        .bind(to: currentForecastO3)
        .disposed(by: bag)
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
        currentForecastPM.value = (defaultAQIAndLevel)
    }
}
