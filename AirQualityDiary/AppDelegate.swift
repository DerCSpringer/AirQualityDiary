//
//  AppDelegate.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/16/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //TODO:  Turn off resource counting -D TRACE_RESOURCES in Pods.RXSwift other swift flags
    //TODO: change from forcast to forecast
    
    let bag = DisposeBag()

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//        let a = AirNowAPI.shared.searchAirQuality(latitude: 34.1278, longitude: -118.1108)
        
        let service = DiaryService()
        //coordinator allows transtions between scenes
        let sceneCoordinator = SceneCoordinator(window: window!)
        //Next instantiate the fisrt view model and instruct the coordinator to set it as its root
        //let diaryEntriesViewModel = DiaryEntriesViewModel(diaryService: service, coordinator: sceneCoordinator)
        let currentConditionsViewModel = CurrentConditionsViewModel(diaryService: service, coordinator: sceneCoordinator)
        //our first scene will display the diary entries
        //let firstScene = Scene.diaryEntries(diaryEntriesViewModel)
        let firstScene = Scene.currentConditions(currentConditionsViewModel)
        //Now that every part in the model, view model and view is setup we must push this to the scene coordinator
        //To display on the screen
        //Then we must transistion to that scene
        sceneCoordinator.transition(to: firstScene, type: .root)
        
        _ = Observable<Int>.interval(1, scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                print("Resource count \(RxSwift.Resources.total)")
            })
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
}

