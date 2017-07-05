//
//  CurrentConditionsViewController.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/30/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

    //only allow one orientation

class CurrentConditionsViewController: UIViewController, BindableType {

    @IBOutlet weak var currentForcastPM: UILabel!
    @IBOutlet weak var currentForcastO3: UILabel!
    @IBOutlet weak var currentPM: UILabel!
    @IBOutlet weak var currentO3: UILabel!
    @IBOutlet weak var tomorrowO3: UILabel!
    @IBOutlet weak var tomorrowPM: UILabel!
    
    let bag = DisposeBag()
    
    
    var viewModel: CurrentConditionsViewModel!
    
    func bindViewModel() {
        
        //We need two api requests to get all the data we need
        //One for current forcast and tomorrow's forcast
        //We need another one for current conditions
        //This should be limited to only one fetch per hour
        //If it's less than an hour then use current data
        //We must create a cache

        //This should be my first VC
        //How can I set this up?
        //Should I pass in a service which won't be used here?
        
        
        viewModel.currentForcastO3.asDriver()
        .drive(currentForcastO3.rx.text)
        .addDisposableTo(bag)
        
        viewModel.currentForcastPM.asDriver()
            .drive(currentForcastPM.rx.text)
            .addDisposableTo(bag)
        
        viewModel.currentPM.asDriver()
            .drive(currentPM.rx.text)
            .addDisposableTo(bag)
        
        viewModel.currentO3.asDriver()
            .drive(currentO3.rx.text)
            .addDisposableTo(bag)
        
        viewModel.tomorrowO3.asDriver()
            .drive(tomorrowO3.rx.text)
            .addDisposableTo(bag)
        
        viewModel.tomorrowPM.asDriver()
            .drive(tomorrowPM.rx.text)
            .addDisposableTo(bag)
    }
}
