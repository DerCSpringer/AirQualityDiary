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

class DiaryEntry: Object, Unboxable {
    dynamic var uid: Int = 0
    //dynamic var title: String = ""
    dynamic var added: Date = Date()
    dynamic var checked: Bool = false
    //dynamic var location:
    dynamic var no2: Float = 0.0
    dynamic var o3: Float = 0.0
    dynamic var dominateParticulate: String = ""
    dynamic var pm25: Float = 0.0
    dynamic var pm10: Float = 0.0
    dynamic var so2: Float = 0.0
    dynamic var co: Float = 0.0
    dynamic var notes: String = ""
    
    // MARK: Init with Unboxer
    convenience required init(unboxer: Unboxer) throws {
        self.init()
        
        no2 = try unboxer.unbox(keyPath: "pollutants.no2")
        o3 = try unboxer.unbox(keyPath: "pollutants.o3")
        pm25 = try unboxer.unbox(keyPath: "pollutants.pm25")
        so2 = try unboxer.unbox(keyPath: "pollutants.so2")
        pm10 = try unboxer.unbox(keyPath: "pollutants.pm10")
        co = try unboxer.unbox(keyPath: "pollutants.co")
        dominateParticulate = try unboxer.unbox(key: "dominant_pollutant_canonical_name")
    }
    
    override class func primaryKey() -> String? {
        return "uid"
    }
}

extension DiaryEntry: IdentifiableType {
    var identity: Int {
        return self.isInvalidated ? 0 : uid
    }
}
