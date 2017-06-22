//
//  DiaryService.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/22/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm

struct DiaryService: DiaryServiceType {
    
    init() {
        do {
            _ = try Realm()
        } catch _ {
        }
    }
    
    fileprivate func withRealm<T>(_ operation: String, action: (Realm) throws -> T) -> T? {
        do {
            let realm = try Realm()
            return try action(realm)
        } catch let err {
            print("Failed \(operation) realm with error: \(err)")
            return nil
        }
    }
    
    @discardableResult
    func createEntry(note: String) -> Observable<DiaryEntry> {
        let result = withRealm("creating") { realm -> Observable<DiaryEntry> in
            let entry = DiaryEntry()
            entry.notes = note
            try realm.write {
                entry.uid = (realm.objects(DiaryEntry.self).max(ofProperty: "uid") ?? 0) + 1
                realm.add(entry)
            }
            return .just(entry)
        }
        return result ?? .error(DiaryServiceError.creationFailed)
    }
    
    @discardableResult
    func delete(entry: DiaryEntry) -> Observable<Void> {
        let result = withRealm("deleting") { realm-> Observable<Void> in
            try realm.write {
                realm.delete(entry)
            }
            return .empty()
        }
        return result ?? .error(DiaryServiceError.deletionFailed(entry))
    }
    
    @discardableResult
    func update(entry: DiaryEntry, note: String) -> Observable<DiaryEntry> {
        let result = withRealm("updating note") { realm -> Observable<DiaryEntry> in
            try realm.write {
                entry.notes = note
            }
            return .just(entry)
        }
        return result ?? .error(DiaryServiceError.updateFailed(entry))
    }
    
    @discardableResult
    func toggle(entry: DiaryEntry) -> Observable<DiaryEntry> {
        let result = withRealm("toggling") { realm -> Observable<DiaryEntry> in
            try realm.write { //MARK: Double check this
                if entry.checked == false {
                    entry.checked = true
                } else {
                    entry.checked = false
                }
            }
            return .just(entry)
        }
        return result ?? .error(DiaryServiceError.toggleFailed(entry))
    }
    
    func entrys() -> Observable<Results<DiaryEntry>> {
        let result = withRealm("getting entries") { realm -> Observable<Results<DiaryEntry>> in
            let realm = try Realm()
            let entries = realm.objects(DiaryEntry.self)
            return Observable.collection(from: entries)
        }
        return result ?? .empty()
    }
}
