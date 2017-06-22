//
//  AddDiaryEntryViewModel.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import Action

struct AddDiaryEntryViewModel {
    
    let entryTitle: String
    let onUpdate: Action<String, Void>
    let onCancel: CocoaAction!
    let disposeBag = DisposeBag()
    let fetcher = AirNowAPI()
    
    init(entry: DiaryEntry, coordinator: SceneCoordinatorType, updateAction: Action<String, Void>, cancelAction: CocoaAction? = nil) {
        entryTitle = String(describing: entry.added)
        onUpdate = updateAction
        onCancel = CocoaAction {
            if let cancelAction = cancelAction {
                cancelAction.execute()
            }
            return coordinator.pop()
        }
        
        onUpdate.executionObservables
            .take(1)
            .subscribe(onNext: { _ in
                coordinator.pop() //all we do if we update is to pop VC rest is done in DiaryEntriesViewModel
            })
            .disposed(by: disposeBag)
    }
}
