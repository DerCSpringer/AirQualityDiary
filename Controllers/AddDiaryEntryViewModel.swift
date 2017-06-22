//
//  AddDiaryEntryViewModel.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct AddDiaryEntryViewModel {
    
    let entryTitle: String
    let onUpdate: Action<String, Void>
    let onCancel: CocoaAction!
    let bag = DisposeBag()
    let weatherQuality = Variable<DiaryEntry?>(nil)


    //We need to do another action for save.  That would simply add teh data to the database
    init(entry: DiaryEntry,
         coordinator: SceneCoordinatorType,
         updateAction: Action<String, Void>,
         cancelAction: CocoaAction? = nil) {
        entryTitle = String(describing: entry.added)
        onUpdate = updateAction

        onCancel = CocoaAction {
            if let cancelAction = cancelAction {
                cancelAction.execute()
            }
            return coordinator.pop()
            
        }
        
        onUpdate.executionObservables
            .take(1)
            .subscribe(onNext: { _ in
                coordinator.pop() //all we do if we update is to pop VC rest is done in DiaryEntriesViewModel
            })
            .disposed(by: bag)
        
            bindOutput()
    }
    
    func bindOutput() { //input will be lat/lon or zipcode when implemented later  output is obs
            let fetcher = AirNowAPI.shared
        fetcher.searchAirQuality(latitude: 34.1278, longitude: -118.1108)
            .map {
                AirNowAPI.shared.formatJSON(jsonArray: $0)
            }
            .map {
                DiaryEntry(airQualityJSON: $0)
        }
        .bind(to: weatherQuality)
        .disposed(by: bag)

    }
}
