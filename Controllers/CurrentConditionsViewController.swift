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
    
    
    var viewModel: CurrentConditionsViewModel!
    
    func bindViewModel() {
        
    
    }
    
}
