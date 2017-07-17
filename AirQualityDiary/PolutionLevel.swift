//
//  PolutionLevel.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 7/14/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift

enum AirQualityLevel {
    case good
    case moderate
    case bad
    case unknown
}

//2 ways
//Send a value + value type and return a AirQuality Observable with infor about airquality color
//When you get an onNext: we'd change color
//Implementation would keep observables for min values of both types
//On updat it would update airqualtyeLevel

//I could have Observables in diaryentry which would //Wouldn't work becuase I'd still have to create a new one each time I look at observables
//I could have a second singleton which would keep track of min values and update with observables

//If I have singleton I just sub to it's observables
//Could return

class PolutionLevel {
    //output
    let polutionType = BehaviorSubject<AirQualityLevel>(value: .unknown)

    private var AQI : Int
    private var polutant : PolutantName
    private let bag = DisposeBag()
    private let minO3 = MinimumIrritationLevelsForPolutants.instance.minO3.asObservable()
    private let minpm25 = MinimumIrritationLevelsForPolutants.instance.minPM25.asObservable()
    
    init(polutantName : PolutantName, withAQI AQI: Int) {
        self.AQI = AQI
        polutant = polutantName
        
        if polutantName == .ozone {
            self.minO3
                .map{ [weak self] min in
                    (self?.polutionSeverity(withMinAQI: min, andCurrentAQI: AQI))!
                }
                .bind(to: polutionType)
                .disposed(by: bag)
        } else if polutantName == .PM2_5 {
            self.minpm25
                .map{ [weak self] min in
                    (self?.polutionSeverity(withMinAQI: min, andCurrentAQI: AQI))!
                }
                .bind(to: polutionType)
                .disposed(by: bag)
        }
    }
        
    private func polutionSeverity(withMinAQI minAQI: Int, andCurrentAQI currentAQI:Int) -> AirQualityLevel {
        if currentAQI == -1 || minAQI == -1{
            return .unknown
        } else if ((currentAQI - minAQI) >= 0) {
            return .bad
        } else if ((currentAQI - minAQI) >= -5) {
            return .moderate
        }  else {
            return .good
        }
    }
}
    //This will be created many times, but I don't want to pass in a million diary service structs

