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

class TaskItem: Object {
    dynamic var uid: Int = 0
    dynamic var title: String = ""
    dynamic var added: Date = Date()
    dynamic var checked: Bool = false
    //dynamic var location:
    dynamic var co2: Float = 0.0
    dynamic var no2: Float = 0.0
    dynamic var o3: Float = 0.0
    dynamic var dominateParticulate: String = ""
    dynamic var pm25: Float = 0.0
    dynamic var so2: Float = 0.0
    dynamic var notes: String = ""
    
    override class func primaryKey() -> String? {
        return "uid"
    }
}

extension TaskItem: IdentifiableType {
    var identity: Int {
        return self.isInvalidated ? 0 : uid
    }
}
