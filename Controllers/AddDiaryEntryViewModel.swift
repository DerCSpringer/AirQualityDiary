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
//    let o3TextAndCondition = Variable<AQIAndLevel>(defaultAQIAndLevel)
//    let pmTextAndCondition = Variable<AQIAndLevel>(defaultAQIAndLevel)
    let o3Text = Variable<Int>(-1)
    let pm25Text = Variable<Int>(-1)

    let isFetching = Variable<Bool>(true)
    let note = Variable<String>("")
    private let onUpdate: Action<DiaryType, Void>
    let onCancel: CocoaAction!
    private let currentLocation : Observable<CLLocationCoordinate2D>
    //private let pollutionItem : PollutionItem
    
    //Finish Conversion for o3Text and pmText Variables
    //I want to move these over and use a pollutionItem struct
    //I think everything in here will use a pollution struct including the init
    //It will emit only a text and condition to the VC
    
    //1.Maybe have two variables one for the diary entry and one for the pollution item.  That's dumb though
    //2. Get pollution item from info give that to the VC.
    //When I need to back out I could assign it to the diary entry
    //How:
    //Pollution item each only have 1 pollutant
    //Create obs of pollution items
    //Take the pollution items with o3 and pm25 and use that

    //TODO:
    //Need an image for our cell
    //errors for unable to fetch
    //Fetch should report back Pollution Item
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
            o3Text.value = entry.o3
            pm25Text.value = entry.pm25
            note.value = entry.notes
            isFetching.value = false
        }
    }
    
    lazy var onSave: Action<String,DiaryType> = Action { [weak self] note in
        let diary = DiaryType(pm25:(self?.pm25Text.value)!, o3:(self?.o3Text.value)!, note:note)
        return .just(diary)
    }
    
    func bindOutput() { //input will be lat/lon or zipcode when implemented later  output is obs
        //I'm sharing fetcher, so anyone can use it, but it's local so that doesn't help much.
        //I can either make it public or I can somehow create a new observable and make that shareable
        
        let fetcher2 = currentLocation.take(1).flatMap() { location -> Observable<[JSONObject]> in
            print(location)
            return AirNowAPI.shared.searchAirQuality(latitude: location.latitude, longitude: location.longitude)
            }
            .flatMap {jsonArray -> Observable<[PollutionItem]> in
                
                let pollutionItems : [PollutionItem] = try unbox(dictionaries: jsonArray)
                return Observable.from(optional: pollutionItems)
            }
        .shareReplay(1)
        
        fetcher2.flatMap{ item in
            Observable.from(item)
        }
            .filter {
                $0.polluteName == .ozone
        }
        
        
        
        let fetcher = currentLocation.take(1).flatMap() { location -> Observable<[JSONObject]> in
            print(location)
            return AirNowAPI.shared.searchAirQuality(latitude: location.latitude, longitude: location.longitude)
            }
            
            .map {
                AirNowAPI.shared.formatJSON(jsonArray: $0)
            }
            .map {
                DiaryEntry(airQualityJSON: $0)
            }
            .shareReplay(1)
        
        fetcher.map { $0.o3 }
            .bind(to: o3Text)
            .disposed(by: bag)
        
        fetcher.map { $0.pm25 }
            .bind(to: pm25Text)
            .disposed(by: bag)
        
        fetcher.map { _ in false }
            .bind(to: isFetching)
            .disposed(by: bag)
    }
    

}
