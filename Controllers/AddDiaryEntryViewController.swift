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
import RxCocoa

class AddDiaryEntryViewController: UIViewController, BindableType {
    @IBOutlet weak var ozone: UILabel!
    @IBOutlet weak var pm25: UILabel!
    @IBOutlet weak var cancel: UIBarButtonItem!
    @IBOutlet weak var addEntry: UIBarButtonItem!
    @IBOutlet weak var note: UITextView!
    @IBOutlet weak var fetchingIndicator: UIActivityIndicatorView!
    
    var viewModel: AddDiaryEntryViewModel!
    private let bag = DisposeBag()
    
    func bindViewModel() {
        note.font = UIFont.preferredFont(forTextStyle: .body)
                
        viewModel.o3TextAndCondition.asObservable()
            .map{ $0.AQI }
            .asDriver(onErrorJustReturn: "Unavailable")
            .drive(self.ozone.rx.text)
            .addDisposableTo(bag)
        
        viewModel.o3TextAndCondition.asObservable()
            .map{ PollutionLevel.colorForPollutionLevel($0.level) }
            .asDriver(onErrorJustReturn: UIColor.blue)
            .drive(self.ozone.rx.textColor)
            .addDisposableTo(bag)
        
        viewModel.pmTextAndCondition.asObservable()
            .map{ return $0.AQI }
            .asDriver(onErrorJustReturn: "Unavailable")
            .drive(self.pm25.rx.text)
            .addDisposableTo(bag)
        
        viewModel.pmTextAndCondition.asObservable()
            .map{ PollutionLevel.colorForPollutionLevel($0.level) }
            .asDriver(onErrorJustReturn: UIColor.blue)
            .drive(self.pm25.rx.textColor)
            .addDisposableTo(bag)
        
        viewModel.note.asDriver()
            .drive(note.rx.text)
        .addDisposableTo(bag)
        
        addEntry.rx.tap
        .withLatestFrom(note.rx.text.orEmpty)
        .subscribe(viewModel.onSave.inputs)
            .disposed(by: bag)
        
        viewModel.isFetching.asDriver()
            .drive(fetchingIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        cancel.rx.action = viewModel.onCancel
    }
}
