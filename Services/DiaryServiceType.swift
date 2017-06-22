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


enum DiaryServiceError: Error {
    case creationFailed
    case updateFailed(DiaryEntry)
    case deletionFailed(DiaryEntry)
    case toggleFailed(DiaryEntry)
}

protocol DiaryServiceType {
    @discardableResult
    func createEntry(note: String) -> Observable<DiaryEntry>
    
    @discardableResult
    func delete(entry: DiaryEntry) -> Observable<Void>
    
    @discardableResult
    func update(entry: DiaryEntry, note: String) -> Observable<DiaryEntry>
    
    @discardableResult
    func toggle(entry: DiaryEntry) -> Observable<DiaryEntry>
    
    func entrys() -> Observable<Results<DiaryEntry>>

}
