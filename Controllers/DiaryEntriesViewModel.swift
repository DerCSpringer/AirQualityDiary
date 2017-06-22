//
//  DiaryEntriesViewModel.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources
import Action

typealias DiarySection = AnimatableSectionModel<String, DiaryEntry>

struct DiaryEntriesViewModel {
    
    let sceneCoordinator: SceneCoordinatorType
    let diaryService: DiaryServiceType
    
    init(diaryService: DiaryServiceType, coordinator: SceneCoordinatorType) {
        self.diaryService = diaryService
        self.sceneCoordinator = coordinator
    }
    
    //This executes when the completed button is tapped
    func onToggle(entry: DiaryEntry) -> CocoaAction {
        return CocoaAction {
            return self.diaryService.toggle(entry: entry).map { _ in }
        }
    }
    //Below actions are executed by the AddVC -> AddVM -> here
    func onDelete(entry: DiaryEntry) -> CocoaAction {
        return CocoaAction {
            return self.diaryService.delete(entry: entry)
        }
    }

    
}
