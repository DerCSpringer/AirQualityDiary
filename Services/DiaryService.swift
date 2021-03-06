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
        // create a few default entries
        do {
            let realm = try Realm()
            if realm.objects(DiaryEntry.self).count == 0 {
                [DiaryType(25, 25, ""),
                 DiaryType(59, 75, ""),
                 DiaryType(120, 70, ""),
                 DiaryType(60, 15, ""),
                 DiaryType(12, 10, "")].forEach {
                    self.createEntry(entry: $0)
                }
            }
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
    func createEntry(entry inputEntry: DiaryType) -> Observable<DiaryEntry> {
        let result = withRealm("creating") { realm -> Observable<DiaryEntry> in
            let entry = DiaryEntry()
            entry.notes = inputEntry.note
            entry.o3 = inputEntry.o3
            entry.pm25 = inputEntry.pm25
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
    func update(entry: DiaryEntry, diary: DiaryType) -> Observable<DiaryEntry> {
        let result = withRealm("updating note") { realm -> Observable<DiaryEntry> in
            try realm.write {
                entry.notes = diary.note
                entry.o3 = diary.o3
                entry.pm25 = diary.pm25
            }
            return .just(entry)
        }
        return result ?? .error(DiaryServiceError.updateFailed(entry))
    }
    
    @discardableResult
    func toggle(entry: DiaryEntry) -> Observable<DiaryEntry> {
        let result = withRealm("toggling") { realm -> Observable<DiaryEntry> in
            try realm.write {
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
    
    func entries() -> Observable<Results<DiaryEntry>> {
        let result = withRealm("getting entries") { realm -> Observable<Results<DiaryEntry>> in
            let realm = try Realm()
            let entries = realm.objects(DiaryEntry.self).sorted(byKeyPath: "added", ascending: false)
            return Observable.collection(from: entries)
        }
        return result ?? .empty()
    }
    
    func minO3Irritation() -> Observable<Int> {
        let result = withRealm("getting entries") { realm -> Observable<Results<DiaryEntry>> in
            let realm = try Realm()
            let entries = realm.objects(DiaryEntry.self).filter("(checked == true) AND (o3 != -1)").sorted(byKeyPath: "o3", ascending: true)
            
            return Observable.collection(from: entries)
            } ?? .empty()
        let min = result
            .flatMap { results -> Observable<Int> in
                if results.isEmpty {
                    return .just(-1)
                }
                return Observable.from(optional: results.first?.o3)
            }
            .distinctUntilChanged()
        return min
    }
    
    func minPM2_5Irritation() -> Observable<Int> {
        let result = withRealm("getting entries") { realm -> Observable<Results<DiaryEntry>> in
            let realm = try Realm()
            let entries = realm.objects(DiaryEntry.self).filter("(checked == true) AND (pm25 != -1)").sorted(byKeyPath: "pm25", ascending: true)
            
            return Observable.collection(from: entries)
            } ?? .empty()
        let min = result
            .flatMap { results -> Observable<Int> in
                if results.isEmpty {
                    return .just(-1)
                }
                return Observable.from(optional: results.first?.pm25)
            }
            .distinctUntilChanged()
        return min
    }
    
}
