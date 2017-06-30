//
//  Scene.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation

enum Scene {
    case diaryEntries(DiaryEntriesViewModel)
    case addEntry(AddDiaryEntryViewModel)
    case currentConditions(CurrentConditionsViewModel)
}
