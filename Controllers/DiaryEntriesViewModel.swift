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
    func onUpdateTitle(entry: DiaryEntry) -> Action<String, Void> {
        return Action { newTitle in
            return self.diaryService.update(entry: entry, note: newTitle).map { _ in }
        }
    }
    
    func onCreateEntry() -> CocoaAction { //action sent to add VC to do  the right thing
        //We create a new diary item
        //If it is created then we instantiate a new AddDiaryEntryViewModel.
        //We pass along an updateCation which updates the anything in the new Diary item, and a cancel action which deletes the diary item
        //This returns an Observable sequence.  We're integrating the whole create-edit procss into a single sequence
        //this completes once teh Add Diary entry Scene closese
        return CocoaAction { _ in
            return self.diaryService
                .createEntry(note: "")
                .flatMap { entry -> Observable<Void> in
                    //Here we setup what happens when each action is executed.
                    //the execution first happen sin the Edit VC
                    //The edit VC then sends the action to it's VM where it was inited
                    //The view model then sends the action back here where it will be executed with the correct func
                    let addDiaryEntryViewModel = AddDiaryEntryViewModel(entry: entry,
                                                          coordinator: self.sceneCoordinator,
                                                          updateAction: self.onUpdateTitle(entry: entry),
                                                          cancelAction: self.onDelete(entry: entry))
                    return self.sceneCoordinator.transition(to: Scene.addEntry(addDiaryEntryViewModel), type: .modal)
            }
        }
    }
}
