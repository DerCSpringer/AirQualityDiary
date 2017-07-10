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
    @IBOutlet weak var diaryEntries: UIBarButtonItem!
    
    //centering is odd
    
    let bag = DisposeBag()
    
    
    var viewModel: CurrentConditionsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //let view = @IBInspectable
        //Only support vertical orientation for this VC
    }
    
    func bindViewModel() {
        
        style()
        
        diaryEntries.rx.action = viewModel.onEntryButtonPress()
        
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
    
    func style() {
        //return colorFromDecimalRGB(229, 231, 218)

    }
}
