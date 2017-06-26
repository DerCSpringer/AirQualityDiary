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
    @IBOutlet weak var canel: UIBarButtonItem!
    @IBOutlet weak var addEntry: UIBarButtonItem!
    @IBOutlet weak var note: UITextView!
    
    var viewModel: AddDiaryEntryViewModel!
    private let bag = DisposeBag()
    
    func bindViewModel() {
        //hmm I might just want to expose the data in the view model instead of going through weatherQuality(a semi-model object)
        viewModel.weatherQuality.asDriver()
            .drive(onNext: { [weak self] weather in
                if let pm = weather?.pm25 {
                self?.pm25.text = String(pm)
                }
            })
            .disposed(by: bag)
        
        viewModel.weatherQuality.asDriver()
            .drive(onNext: { [weak self] weather in
                if let o3 = weather?.o3 {
                    self?.ozone.text = String(o3)
                }
            })
            .disposed(by: bag)
        
        addEntry.rx.tap
        .withLatestFrom(note.rx.text.orEmpty)
        .subscribe(viewModel.save.inputs)
            .disposed(by: bag)
    }

}
