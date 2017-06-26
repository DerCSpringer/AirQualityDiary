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
    
    

    let onCancel: CocoaAction!
    let save : Action<String, DiaryType>
    let bag = DisposeBag()
    let weatherQuality = Variable<DiaryEntry?>(nil)

    //We need to do another action for save.  That would simply add teh data to the database
    //Probably want another item in here to indicate whether note is updated or I create a new entry
    init(entry: DiaryEntry,
         coordinator: SceneCoordinatorType,
         updateAction: Action<DiaryType, Void>,
         cancelAction: CocoaAction? = nil) {
        
        let onUpdate: Action<DiaryType, Void>
        
        var pm25 = Float(-1.0)
        var o3 = Float(-1.0)

        weatherQuality.asObservable()
            .subscribe(onNext: { entry in
                pm25 = entry?.pm25 ?? -1.0
            })
        .disposed(by: bag)
        
        weatherQuality.asObservable()
            .subscribe(onNext: { entry in
                o3 = entry?.o3 ?? -1.0
            })
            .disposed(by: bag)
        

        save = Action<String, DiaryType> { note in
            let diary = DiaryType(pm25: pm25, o3: o3, note:note)
            return .just(diary)
        }
        
        //Ok working it seems, but I need the diaryEntriesViewModel to get notice of a DiaryType
        //currently this returns a DiaryType, but instead I would like it to have a DiaryType as inputer and void as output


        
//        garbage.executionObservables
//        .take(1)
//            .subscribe(onNext: {entry in
//                onUpdate.execute(entry)
//                coordinator.pop()
//            })
//            .disposed(by: bag)
        
//        .bind(to:onUpdate.inputs)
//        .disposed(by: bag)
        
        onUpdate = updateAction
        
        save.executionObservables
            .take(1)
            .flatMap { $0 }
            .subscribe(onNext: { entry in
                print("Diary entry in Add DiaryEntry VM \(entry)")
                onUpdate.execute(entry)
            })
            .disposed(by: bag)

        onCancel = CocoaAction {
            if let cancelAction = cancelAction {
                cancelAction.execute()
            }
            return coordinator.pop()
            
        }
        
        onUpdate.executionObservables //This needs to take one of the diaryType not the note
            .take(1)  //This takes the note, but we also need the weather quality
                        //I should also only reveal data to the VC instead of the model object(I think)
            .subscribe(onNext: { _ in
                coordinator.pop() //all we do if we update is to pop VC rest is done in DiaryEntriesViewModel
            })
            .disposed(by: bag)
        
            bindOutput() //always called not great if we just want to edit the cell//TODO: here
    }
    
    //TODO:  How can I pass the updated DiaryEntry.  I just created a tuple which stores all the data as a DiaryEntryType
    //I don't think this is good becuase it's a little bit confusing to put it all together in a tuple.
    //Currently this viewmodel creates the data object, which is loaded from the tableviewModel
    //I have access to this through the viewmodel property
    //Maybe I should just send this whole DiaryEntry to the DiaryEntriesVM through the action and send it to the service to update the
    //Diary Entry
    
//    lazy var update: Action<String, Void> = { this in
//        return Action { task in
//            
//        }
//    }(self)
    
    func bindOutput() { //input will be lat/lon or zipcode when implemented later  output is obs
        //I'm sharing fetcher, so anyone can use it, but it's local so that doesn't help much.
        
        //I can either make it public or I can somehow create a new observable and make that shareable
            let fetcher = AirNowAPI.shared
        fetcher.searchAirQuality(latitude: 34.1278, longitude: -118.1108)
            .map {
                AirNowAPI.shared.formatJSON(jsonArray: $0)
            }
            .map {
                DiaryEntry(airQualityJSON: $0)
        }
        .shareReplay(1)
        .bind(to: weatherQuality)
        .disposed(by: bag)
    }
}
