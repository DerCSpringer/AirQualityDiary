//
//  UILabel+Rx.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 7/17/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


extension Reactive where Base: UILabel {
    public var textColor: UIBindingObserver<Base, UIColor?> {
        return UIBindingObserver(UIElement: self.base) { label, textColor in
            label.textColor = textColor
        }
    }
}
