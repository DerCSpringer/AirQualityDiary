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

class DiaryEntry: Object {
    dynamic var uid: Int = 0
    dynamic var added: Date = Date()
    dynamic var checked: Bool = false
    dynamic var o3: Int = -1
    dynamic var pm25: Int = -1
    dynamic var notes: String = ""
    
    override class func primaryKey() -> String? {
        return "uid"
    }
}

extension DiaryEntry: IdentifiableType {
    var identity: Int {
        return self.isInvalidated ? 0 : uid
    }
}
