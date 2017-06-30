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
import CoreLocation

class AddDiaryEntryViewModel {
    private let bag = DisposeBag()
    let o3Text = Variable<Int>(-1)
    let pm25Text = Variable<Int>(-1)
    let isFetching = Variable<Bool>(true)
    private let onUpdate: Action<DiaryType, Void>
    let onCancel: CocoaAction!
    private let locationManager = CLLocationManager()
    private let currentLocation : Observable<CLLocation>
    

    
    //TODO: Add delete and Edit for cells
    //Need an image for our cell
    //Sort data by ozone
    //errors for unable to fetch
    //better note section and AddEntryVC
    //Add later
    //We could add something at the bottom of the DiaryEntriesTV to display the minium amount that bothers someone.
    //this could be displayed on the forcast and so forth
    //opening display could have black background
    //Forground text is different color depending on how bad teh forcast for the next day is for you
    
    
    init(entry: DiaryEntry,
         coordinator: SceneCoordinatorType,
         updateAction: Action<DiaryType, Void>,
         cancelAction: CocoaAction? = nil) {
        
        
        currentLocation = locationManager.rx.didUpdateLocations
            .map() { locations in
                //print(locations)
                return locations[0]
            }
            .filter() { location in
                return location.horizontalAccuracy <= kCLLocationAccuracyKilometer
        }
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
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
        bindOutput()
    }
    
    lazy var onSave: Action<String,DiaryType> = Action { [weak self] note in
        let diary = DiaryType(pm25:(self?.pm25Text.value)!, o3:(self?.o3Text.value)!, note:note)
        return .just(diary)
    }
    
    func bindOutput() { //input will be lat/lon or zipcode when implemented later  output is obs
        //I'm sharing fetcher, so anyone can use it, but it's local so that doesn't help much.
        //I can either make it public or I can somehow create a new observable and make that shareable
        
        let fetcher = currentLocation.take(1).flatMap() { location -> Observable<[AirNowAPI.JSONObject]> in
            print(location)
            return AirNowAPI.shared.searchAirQuality(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        
        //let fetcher = AirNowAPI.shared.searchAirQuality(latitude: 34.1278, longitude: -118.1108)
            //fetcher
            .map {
                AirNowAPI.shared.formatJSON(jsonArray: $0)
            }
            .map {
                DiaryEntry(airQualityJSON: $0)
            }
            .shareReplay(1)
        
        fetcher.map { entry in
            return entry.o3
            }
            .bind(to: o3Text)
            .disposed(by: bag)
        
        fetcher.map { entry in
            return entry.pm25
            }
            .bind(to: pm25Text)
            .disposed(by: bag)
        
        fetcher.map { _ in false }
            .bind(to: isFetching)
            .disposed(by: bag)
    }
}
//
//    let onCancel: CocoaAction!
//    //var save : Action<String, DiaryType>
//    let bag = DisposeBag()
//    let weatherQuality = Variable<DiaryEntry?>(nil)
//    let o3Text = Variable<Int>(-1)
//    let pm25Text = Variable<Int>(-1)
//    let isFetching = Variable<Bool>(true)
//    
//    var save: Action<String, DiaryType> { note in
//        let diary = DiaryType(pm25: 3, o3: 4, note:"")
//        return .just(diary)
//    }
//
//    init(entry: DiaryEntry,
//         coordinator: SceneCoordinatorType,
//         updateAction: Action<DiaryType, Void>,
//         cancelAction: CocoaAction? = nil) {
//
//        let onUpdate: Action<DiaryType, Void>
//        
//        var pm25 = Int(-1)
//        var o3 = Int(-1)
//
//        pm25Text.asObservable()
//            .subscribe(onNext: { pm25Text in
//                pm25 = pm25Text
//            })
//        .disposed(by: bag)
//        
//        o3Text.asObservable()
//            .subscribe(onNext: { o3Text in
//                o3 = o3Text
//            })
//            .disposed(by: bag)
//        
//        onCancel = CocoaAction {
//            if let cancelAction = cancelAction {
//                cancelAction.execute()
//            }
//            return coordinator.pop()
//        }
//
//        onUpdate = updateAction
//        
//        save.executionObservables
//            .take(1)
//            .flatMap { $0 }
//            .subscribe(onNext: { entry in
//                print("Diary entry in Add DiaryEntry VM \(entry)")
//                onUpdate.execute(entry)
//            })
//            .disposed(by: bag)
//
//        onUpdate.executionObservables //This needs to take one of the diaryType not the note
//            .take(1)  //This takes the note, but we also need the weather quality
//                        //I should also only reveal data to the VC instead of the model object(I think)
//            .subscribe(onNext: { _ in
//                coordinator.pop() //all we do if we update is to pop VC rest is done in DiaryEntriesViewModel
//            })
//            .disposed(by: bag)
//        
//            bindOutput() //always called not great if we just want to edit the cell//TODO: here
//    }
//    
//    //TODO:  How can I pass the updated DiaryEntry.  I just created a tuple which stores all the data as a DiaryEntryType
//    //I don't think this is good becuase it's a little bit confusing to put it all together in a tuple.
//    //Currently this viewmodel creates the data object, which is loaded from the tableviewModel
//    
//    func bindOutput() { //input will be lat/lon or zipcode when implemented later  output is obs
//        //I'm sharing fetcher, so anyone can use it, but it's local so that doesn't help much.
//        
//        //I can either make it public or I can somehow create a new observable and make that shareable
//            let fetcher = AirNowAPI.shared.searchAirQuality(latitude: 34.1278, longitude: -118.1108)
//            .map {
//                AirNowAPI.shared.formatJSON(jsonArray: $0)
//            }
//            .map {
//                DiaryEntry(airQualityJSON: $0)
//        }
//        .shareReplay(1)
//        
//        fetcher.map { entry in
//            return entry.o3
//        }
//        .bind(to: o3Text)
//        .disposed(by: bag)
//        
//        fetcher.map { entry in
//            return entry.pm25
//            }
//            .bind(to: pm25Text)
//            .disposed(by: bag)
//        
//        fetcher.map { _ in false }
//        .bind(to: isFetching)
//        .disposed(by: bag)
//    }
//}
