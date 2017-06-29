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
    @IBOutlet weak var cancel: UIBarButtonItem!
    @IBOutlet weak var addEntry: UIBarButtonItem!
    @IBOutlet weak var note: UITextView!
    @IBOutlet weak var fetchingIndicator: UIActivityIndicatorView!
    
    var viewModel: AddDiaryEntryViewModel!
    private let bag = DisposeBag()
    
    func bindViewModel() {
        //hmm I might just want to expose the data in the view model instead of going through weatherQuality(a semi-model object)
        
        viewModel.pm25Text.asDriver()
            .drive(onNext: { [weak self] pm25 in
                self?.pm25.text = String(pm25)
            })
            .disposed(by: bag)
        
        viewModel.o3Text.asDriver()
            .drive(onNext: { [weak self] o3 in
                self?.ozone.text = String(o3)
            })
            .disposed(by: bag)
        
        addEntry.rx.tap
        .withLatestFrom(note.rx.text.orEmpty)
        .subscribe(viewModel.onSave.inputs)
            .disposed(by: bag)
        
        viewModel.isFetching.asDriver()
            .drive(fetchingIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.isFetching.asDriver()
            .skip(1)
            .map{ _ in true }
            .drive(fetchingIndicator.rx.isHidden)
            .addDisposableTo(bag)
        
        cancel.rx.action = viewModel.onCancel
    }
}
