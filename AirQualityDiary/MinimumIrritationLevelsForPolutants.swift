//
//  MinimumIrritationLevelsForPollutants.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 7/14/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class MinimumIrritationLevelsForPollutants {
    static let instance = MinimumIrritationLevelsForPollutants()
    //output
    private (set) var minPM25 = Variable<Int>(-1)
    private (set) var minO3 = Variable<Int>(-1)
    
    private let bag = DisposeBag()
    //might wanna init this and send in service maybe from appdelegate
    private init() {
        let service = DiaryService()
        
        //setup correct sequence for Driver
        service.minPM2_5Irritation()
        .bind(to: minPM25)
        .disposed(by: bag)
        
        service.minO3Irritation()
        .bind(to: minO3)
        .disposed(by: bag)
    }
}
