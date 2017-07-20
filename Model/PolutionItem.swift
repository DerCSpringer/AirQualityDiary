//
//  PollutionItem.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 7/7/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import Unbox
import RxCocoa
import RxSwift

enum ForecastDate {
    case tomorrow
    case today
    case other
}

enum PollutantName {
    case ozone
    case PM2_5
    case NO2
    case PM10
    case CO
    case other
}
struct PollutionItem {
    let forecastFor : ForecastDate?
    let AQI : Int
    let polluteName : PollutantName
    var pollutionType = BehaviorSubject<AirQualityLevel>(value: .unknown)
    fileprivate var polluteLevel : PollutionLevel?
    fileprivate let bag = DisposeBag()
}

extension PollutionItem {
    static func pollutionItemsFrom(diary: DiaryEntry) -> Observable<[PollutionItem]> {
        return Observable.create { observer in
            let bag = DisposeBag() //TODO: Is this ok to put in an observable?
            let polluteLevelPM25 = PollutionLevel.init(pollutantName:.PM2_5 , withAQI: diary.pm25)
            let airQualityLevelPM25 = BehaviorSubject<AirQualityLevel>(value: .unknown)
            polluteLevelPM25.pollutionType.bind(to: airQualityLevelPM25)  //TODO: Is it ok to bind when creating an Obs?
            .disposed(by: bag)
            
            let pm = PollutionItem.init(forecastFor: nil,
                                        AQI: diary.pm25,
                                        polluteName: .PM2_5,
                                        pollutionType: airQualityLevelPM25,
                                        polluteLevel: polluteLevelPM25)
            
            let polluteLevelO3 = PollutionLevel.init(pollutantName:.ozone , withAQI: diary.o3)
            let airQualityLevelO3 = BehaviorSubject<AirQualityLevel>(value: .unknown)
            polluteLevelO3.pollutionType.bind(to: airQualityLevelO3)
            .disposed(by: bag)
            
            let o3 = PollutionItem.init(forecastFor: nil,
                                        AQI: diary.o3,
                                        polluteName: .ozone,
                                        pollutionType: airQualityLevelO3,
                                        polluteLevel: polluteLevelO3)
            
            let polutionItems = [pm, o3]
            observer.onNext(polutionItems)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}

extension PollutionItem: Unboxable {
    init(unboxer: Unboxer) throws {
        let dateFormat = DateFormatter()
        let today = Date()
        let tomorrow = today.addingTimeInterval(86400)
        
        dateFormat.dateFormat = "yyyy-MM-dd "
        self.AQI = try unboxer.unbox(key: "AQI")
        
        let polluteName : String = try unboxer.unbox(key: "ParameterName")
        switch polluteName {
        case "CO":
            self.polluteName = .CO
        case "PM2.5":
            self.polluteName = .PM2_5
        case "NO2":
            self.polluteName = .NO2
        case "PM10":
            self.polluteName = .PM10
        case "O3":
            self.polluteName = .ozone
        default:
            self.polluteName = .other
        }

        let date : String? = try? unboxer.unbox(key: "DateForecast")
        
        if date == nil {
            self.forecastFor = nil
        } else if date == dateFormat.string(from: today){
            self.forecastFor = .today
        } else if date == dateFormat.string(from: tomorrow){
            self.forecastFor = .tomorrow
        } else {
            self.forecastFor = .other
        }
        
        polluteLevel = PollutionLevel.init(pollutantName: self.polluteName, withAQI: AQI)
        polluteLevel?.pollutionType.bind(to: pollutionType)
        .disposed(by: bag)
    }
}
