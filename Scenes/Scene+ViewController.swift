//
//  Scene+ViewController.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import UIKit

extension Scene {
    func viewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        switch self { //Switch on the type of scene we want to display
        case .diaryEntries(let viewModel):
            let nc = storyboard.instantiateViewController(withIdentifier: "DiaryEntries") as! UINavigationController
            var vc = nc.viewControllers.first as! DiaryEntriesViewController
            //We call this bind after the view is loaded and outlets are loaded
            vc.bindViewModel(to: viewModel)
            return nc
            
        case .addEntry(let viewModel):
            let nc = storyboard.instantiateViewController(withIdentifier: "AddDiaryEntry") as! UINavigationController
            var vc = nc.viewControllers.first as! AddDiaryEntryViewController
            vc.bindViewModel(to: viewModel)
            return nc
            
        case .currentConditions(let viewModel):
            let nc = storyboard.instantiateViewController(withIdentifier: "CurrentConditions") as! UINavigationController
            var vc = nc.viewControllers.first as! CurrentConditionsViewController
            vc.bindViewModel(to: viewModel)
            return nc
        }
    }
}
