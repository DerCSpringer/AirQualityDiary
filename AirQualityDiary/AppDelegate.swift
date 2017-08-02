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
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let service = DiaryService()
        //coordinator allows transtions between scenes
        let sceneCoordinator = SceneCoordinator(window: window!)
        //Next instantiate the fisrt view model and instruct the coordinator to set it as its root
        let currentConditionsViewModel = CurrentConditionsViewModel(diaryService: service, coordinator: sceneCoordinator)
        //our first scene will display the diary entries
        let firstScene = Scene.currentConditions(currentConditionsViewModel)
        //Now that every part in the model, view model and view is setup we must push this to the scene coordinator
        //To display on the screen
        //Then we must transistion to that scene
        sceneCoordinator.transition(to: firstScene, type: .root)
        return true
    }
    
}

