//
//  AddDiaryEntryViewModel.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Action
import CoreLocation
import Unbox


class AddDiaryEntryViewModel {
    private let bag = DisposeBag()
    let o3TextAndCondition = Variable<AQIAndLevel>(defaultAQIAndLevel)
    let pmTextAndCondition = Variable<AQIAndLevel>(defaultAQIAndLevel)

    let isFetching = Variable<Bool>(true)
    let note = Variable<String>("")
    private let onUpdate: Action<DiaryType, Void>
    let onCancel: CocoaAction!
    private let currentLocation : Observable<CLLocationCoordinate2D>

    //TODO:
    //errors for unable to fetch: REachability
    //Add later
    //We could add something at the bottom of the DiaryEntriesTV to display the minium amount that bothers someone.
    //this could be displayed on the forcast and so forth
    //opening display could have black background
    //Forground text is different color depending on how bad teh forcast for the next day is for you
    
    
    init(entry: DiaryEntry,
         coordinator: SceneCoordinatorType,
         updateAction: Action<DiaryType, Void>,
         cancelAction: CocoaAction? = nil) {
        
        currentLocation = GeolocationService.instance.location.asObservable()
        .distinctUntilChanged { loc1, loc2 in //prevents constant fetching in some instances
                return(loc1.latitude == loc2.latitude && loc1.longitude == loc2.longitude)
        }

        onUpdate = updateAction
        onUpdate.executionObservables //This needs to take one of the diaryType not the note
            .take(1)  //This takes the note, but we also need the weather quality
            //I should also only reveal data to the VC instead of the model object(I think)
            .subscribe(onNext: { _ in
                coordinator.pop() //all we do if we update is to pop VC rest is done in DiaryEntriesViewModel
            })
            .disposed(by: bag)
        
        onCancel = CocoaAction {
            if let cancelAction = cancelAction {
                cancelAction.execute()
            }
            return coordinator.pop()
        }
        
        onSave.executionObservables
            .take(1)
            .flatMap { $0 }
            .subscribe(onNext: { [weak self] entry in
                print("Diary entry in Add DiaryEntry VM \(entry)")
                self?.onUpdate.execute(entry)
            })
            .disposed(by: bag)
        
        if (entry.added.timeIntervalSinceNow > -1) {//If DiaryEntry is being added and not edited
            print(entry.added.timeIntervalSinceNow)
            bindOutput()
        } else {
            let pollute = PollutionItem.pollutionItemsFrom(diary: entry)
                .flatMap{ Observable.from($0) }
                .shareReplay(2) //Immediately emits both pm and o3 entries
            
            combineTitleAndPollutionTypeFor(pollute, polluteName: .ozone)
            .bind(to: o3TextAndCondition)
            .disposed(by: bag)
            
            combineTitleAndPollutionTypeFor(pollute, polluteName: .PM2_5)
            .bind(to: pmTextAndCondition)
            .disposed(by: bag)
            
            note.value = entry.notes
            isFetching.value = false
        }
    }
    
    lazy var onSave: Action<String,DiaryType> = Action { [weak self] note in
        //TODO: Fix this.  Not a fan
        var pm : Int
        var o3 : Int
        if let tempPM = Int((self?.pmTextAndCondition.value.AQI)!) {
            pm = tempPM
        } else {
            pm = -1
        }
        
        if let tempO3 = Int((self?.o3TextAndCondition.value.AQI)!) {
            o3 = tempO3
        } else {
            o3 = -1
        }
        
        let diary = DiaryType(pm25:pm, o3:o3, note:note)
        return .just(diary)
    }
    
    func bindOutput() {
        let fetcher = currentLocation.take(1).flatMap() { location -> Observable<[JSONObject]> in
            print(location)
            return AirNowAPI.shared.searchAirQuality(latitude: location.latitude, longitude: location.longitude)
            }
            .flatMap {jsonArray -> Observable<[PollutionItem]> in
                
                let pollutionItems : [PollutionItem] = try unbox(dictionaries: jsonArray)
                return Observable.from(optional: pollutionItems)
            }
        .shareReplay(1)
        
        let fetchedResults = fetcher.flatMap{ item in
            Observable.from(item)
        }
        .shareReplay(1)
        
        combineTitleAndPollutionTypeFor(fetchedResults, polluteName: .ozone)
        .bind(to: self.o3TextAndCondition)
        .disposed(by: bag)
        
        combineTitleAndPollutionTypeFor(fetchedResults, polluteName: .PM2_5)
        .bind(to: self.pmTextAndCondition)
        .disposed(by: bag)
        
        fetcher.map { _ in false }
            .bind(to: isFetching)
            .disposed(by: bag)
    }
    
    //TODO: duplicated func from CurrentConditionsVM
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
}
