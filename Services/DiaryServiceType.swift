//
//  DiaryServiceType.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/16/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

//TODO: must be some way to make DiaryType thing better
typealias DiaryType = (pm25:Int, o3:Int, note: String)

enum DiaryServiceError: Error {
    case creationFailed
    case updateFailed(DiaryEntry)
    case deletionFailed(DiaryEntry)
    case toggleFailed(DiaryEntry)
}

protocol DiaryServiceType {
    @discardableResult
    func createEntry(entry: DiaryType) -> Observable<DiaryEntry>
    
    @discardableResult
    func delete(entry: DiaryEntry) -> Observable<Void>
    
    @discardableResult
    func update(entry: DiaryEntry, diary: DiaryType) -> Observable<DiaryEntry>
    
    @discardableResult
    func toggle(entry: DiaryEntry) -> Observable<DiaryEntry>
    
    func minO3Irritation() -> Observable<Int>
    
    func minPM2_5Irritation() -> Observable<Int>
    
    func entries() -> Observable<Results<DiaryEntry>>
}
