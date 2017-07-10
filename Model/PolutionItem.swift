//
//  PolutionItem.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 7/7/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import Unbox

enum ForecastDate {
    case tomorrow
    case today
}

enum PolutantName {
    case ozone
    case PM2_5
    case NO2
    case PM10
    case CO
    case other
}
struct PolutionItem {
    let forecastFor : ForecastDate?
    let AQI : Int
    let polututeName : PolutantName
}

extension PolutionItem: Unboxable {
    init(unboxer: Unboxer) throws {
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd "
        self.AQI = try unboxer.unbox(key: "AQI")
        
        let polututeName : String = try unboxer.unbox(key: "ParameterName")
        switch polututeName {
        case "CO":
            self.polututeName = .CO
        case "PM2.5":
            self.polututeName = .PM2_5
        case "NO2":
            self.polututeName = .NO2
        case "PM10":
            self.polututeName = .PM10
        case "O3":
            self.polututeName = .ozone
        default:
            self.polututeName = .other
        }

        let date : String? = try? unboxer.unbox(key: "DateForecast")

        if date == nil {
            self.forecastFor = nil
        } else if date == dateFormat.string(from: Date()){
            self.forecastFor = .today
        } else {
            self.forecastFor = .tomorrow
        }
        
    }
}
