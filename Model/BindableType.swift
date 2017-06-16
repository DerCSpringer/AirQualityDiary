//
//  BindableType.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/16/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import UIKit
import RxSwift

protocol BindableType { //All view models must abide by this protocol.  It allows for a binding between VC-VM
    associatedtype ViewModelType
    
    var viewModel: ViewModelType! { get set }
    
    func bindViewModel()
}

extension BindableType where Self: UIViewController {
    mutating func bindViewModel(to model: Self.ViewModelType) { //This function in the VCs will connect UI elements to Observables and actions in the VM
        //We don't use ViewDidLoad, becuase our viewmodel must be assigned before viewDidLoad
        viewModel = model
        loadViewIfNeeded()
        bindViewModel()//This is called in the extension on Scene+VC
    }
}
