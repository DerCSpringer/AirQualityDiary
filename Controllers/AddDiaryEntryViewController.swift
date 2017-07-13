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
        
        viewModel.pm25Text.asDriver()
            .drive(onNext: { [weak self] pm25 in
                if pm25 == -1 {
                    self?.pm25.text = "Unavailable"
                } else {
                self?.pm25.text = String(pm25)
                }
            })
            .disposed(by: bag)
        
        viewModel.o3Text.asDriver()
            .drive(onNext: { [weak self] o3 in
                if o3 == -1 {
                    self?.ozone.text = "Unavailable"
                } else {
                self?.ozone.text = String(o3)
                }
            })
            .disposed(by: bag)
        
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
