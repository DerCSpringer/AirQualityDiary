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

    //Add later
    //We could add something at the bottom of the DiaryEntriesTV to display the minium amount that bothers someone.
    //this could be displayed on the Forecast and so forth

    init(entry: DiaryEntry,
         coordinator: SceneCoordinatorType,
         updateAction: Action<DiaryType, Void>,
         cancelAction: CocoaAction? = nil) {

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
                self?.onUpdate.execute(entry)
            })
            .disposed(by: bag)
        
        if (entry.added.timeIntervalSinceNow > -1) {//If DiaryEntry is being added and not edited
            bindOutput()
        } else {
            let pollutes = PollutionItem.pollutionItemsFrom(diary: entry)
                .flatMap{ Observable.from($0) }
                .shareReplay(2) //Immediately emits both pm and o3 entries
            
            PollutionLevel.combineTitleAndPollutionTypeFor(pollutes, polluteName: .ozone)
            .bind(to: o3TextAndCondition)
            .disposed(by: bag)
            
            PollutionLevel.combineTitleAndPollutionTypeFor(pollutes, polluteName: .PM2_5)
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
        let api = AirNowAPI.instance
        let fetcher = api.currentConditions.asObservable()
            .filter { $0.first?.count != 0 } //filter out empty data
            .flatMap {jsonArray -> Observable<[PollutionItem]> in
                let pollutionItems : [PollutionItem] = try unbox(dictionaries: jsonArray)
                return Observable.from(optional: pollutionItems)
            }
        .shareReplay(1)
        
        let fetchedResults = fetcher.flatMap{ item in
            Observable.from(item)
        }
        
        PollutionLevel.combineTitleAndPollutionTypeFor(fetchedResults, polluteName: .ozone)
        .bind(to: self.o3TextAndCondition)
        .disposed(by: bag)
        
        PollutionLevel.combineTitleAndPollutionTypeFor(fetchedResults, polluteName: .PM2_5)
        .bind(to: self.pmTextAndCondition)
        .disposed(by: bag)
        
        api.currentFetchIsRunning.asObservable()
            .bind(to: isFetching)
            .disposed(by: bag)
    }
}
