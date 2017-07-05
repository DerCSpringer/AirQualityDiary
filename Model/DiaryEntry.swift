//
//  DiaryEntry.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/16/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RealmSwift
import RxDataSources
import Unbox

typealias JSONObject = [String : Any]

class DiaryEntry: Object {
    dynamic var uid: Int = 0
    dynamic var added: Date = Date()
    dynamic var checked: Bool = false
    dynamic var o3: Int = -1
    dynamic var pm25: Int = -1
    dynamic var notes: String = ""
    
    // MARK: Init with Unboxer
//    convenience required init(unboxer: Unboxer) throws {
//        self.init()
//        let name : String
//        name = try unboxer.unbox(key: "ParameterName")
//        switch name {
//        case "O3":
//            o3 = try unboxer.unbox(key: "AQI")
//        case "PM25":
//            pm25 = try unboxer.unbox(key: "AQI")
//        default:
//            break
//        }
//        //o3 = try unboxer.unbox(keyPath: "pollutants.o3")
//        //pm25 = try unboxer.unbox(keyPath: "pollutants.pm25")
////        so2 = try unboxer.unbox(keyPath: "pollutants.so2")
////        pm10 = try unboxer.unbox(keyPath: "pollutants.pm10")
////        co = try unboxer.unbox(keyPath: "pollutants.co")
////        dominateParticulate = try unboxer.unbox(key: "dominant_pollutant_canonical_name")
//    }
    
    convenience required init(airQualityJSON: JSONObject) { //sub classes must provide this init
        self.init()
        o3 = airQualityJSON["O3"] as? Int ?? -1
        pm25 = airQualityJSON["PM2.5"] as? Int ?? -1
    }
    
//    convenience init(note: String, particulateMatter25: Int, ozone: Int) {
//        self.init()
//        o3 = ozone
//        pm25 = particulateMatter25
//        notes = note
//    }
    
    override class func primaryKey() -> String? {
        return "uid"
    }
    
//    static func unboxMany(airQuality: [JSONObject]) -> DiaryEntry {
//        for obj in airQuality {
//            return (try? unbox(dictionary: obj) as DiaryEntry) ?? nil
//        }
//        //return (try? unbox(dictionaries: tweets, allowInvalidElements: true) as DiaryEntry) ?? []
//        //return (try? unbox(dictionaries: tweets, allowInvalidElements: true) as DiaryEntry) ?? []
//        //let a = try! Unbox.unbox(dictionary: airQuality) as DiaryEntry
//        return (try! unbox(dictionary: airQuality) as DiaryEntry)
//        //return (try? unbox(dictionaries: airQuality, allowInvalidElements: false) as JSONObject) ?? nil
//    }
//    static func unboxAll(airQuality: [JSONObject]) -> DiaryEntry {
//        try Unboxer.performCustomUnboxing(array: airQuality) {array in
//            for
//        }
        
//        try Unboxer.performCustomUnboxing(array: airQuality, closure: { unboxer in
//            
//            var diaryEntry = DiaryEntry()
//            let name = 
//            diaryEntry.o3 =
            //var model = Model(dependency: dependency)
            //model.name = unboxer.unbox(key: "name")
            //model.count = unboxer.unbox(key: "count")
            
            //return model
//        })
//    }
    
    

}

struct PolutionTypes {
    var polutionEntries : [JSONObject]
}

extension DiaryEntry: IdentifiableType {
    var identity: Int {
        return self.isInvalidated ? 0 : uid
    }
}
