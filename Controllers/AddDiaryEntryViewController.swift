//
//  AddDiaryEntryViewController.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class AddDiaryEntryViewController: UIViewController, BindableType {
    @IBOutlet weak var ozone: UILabel!
    @IBOutlet weak var pm25: UILabel!
    
    var viewModel: AddDiaryEntryViewModel!
    private let bag = DisposeBag()
    
    func bindViewModel() {
        viewModel.weatherQuality.asDriver()
            .drive(onNext: { [weak self] weather in
                self?.pm25.text = String(describing: weather?.pm25)
            })
            .disposed(by: bag)
        
        viewModel.weatherQuality.asDriver()
            .drive(onNext: { [weak self] weather in
                self?.ozone.text = String(describing: weather?.o3)
            })
            .disposed(by: bag)
//        viewModel.weatherQuality.asDriver()
//            .drive(onNext: { [weak self] weather in
//                self?.ozone.text = String(describing: weather?.o3)
//        }
//                .disposed(by: bag)
        
    }

}
