//
//  PollutionLevel.swift
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

struct PollutionLevel {

    private let bag = DisposeBag()
    private static let minO3 = MinimumIrritationLevelsForPollutants.instance.minO3.asObservable()
    private static let minpm25 = MinimumIrritationLevelsForPollutants.instance.minPM25.asObservable()
    
    private static func pollutionSeverity(withMinAQI minAQI: Int, andCurrentAQI currentAQI:Int) -> AirQualityLevel {
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
    
    static func combineTitleAndPollutionTypeFor(_ obs: Observable<PollutionItem>, polluteName:PollutantName) -> Observable<AQIAndLevel> {
        let pollute = obs.filter {
            $0.polluteName == polluteName
            }
            .shareReplay(1)
        
        let aqi = pollute.map {
            $0.AQI
        }
        let min: Observable<Int>
        
        if polluteName == .ozone {
            min = minO3
        } else if polluteName == .PM2_5 {
            min = minpm25
        } else {
            return Observable.of(AQIAndLevel("Unavailable", .unknown))
        }
        
        return Observable.combineLatest(aqi, min){ AQI, min in
            let level = PollutionLevel.pollutionSeverity(withMinAQI: min, andCurrentAQI: AQI)
            let aqiString = (AQI == -1) ? "Unavailable" : String(AQI)
            return AQIAndLevel(aqiString, level)
        }
    }
}

extension PollutionLevel {
    static func colorForPollutionLevel(_ airLevel:AirQualityLevel) -> UIColor {
        switch airLevel {
        case .good:
            return #colorLiteral(red: 0.1539898217, green: 1, blue: 0, alpha: 1)
        case .bad:
            return #colorLiteral(red: 1, green: 0.3244201541, blue: 0, alpha: 1)
        case .moderate:
            return #colorLiteral(red: 0.9828135371, green: 1, blue: 0, alpha: 1)
        default:
            return #colorLiteral(red: 0.9105119109, green: 0.9008874893, blue: 0.6748702526, alpha: 1)
        }
    }
}
    //This will be created many times, but I don't want to pass in a million diary service structs
