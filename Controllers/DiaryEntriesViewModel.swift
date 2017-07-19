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
    let bag = DisposeBag()
    
    init(diaryService: DiaryServiceType, coordinator: SceneCoordinatorType) {
        self.diaryService = diaryService
        self.sceneCoordinator = coordinator
    }
    
    //This executes when the bad? button is tapped
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
    func onUpdateEntry(entry: DiaryEntry) -> Action<DiaryType, Void> {
        return Action { diary in
            print("Diary entry in onUpdateEntry in VM: \(diary)")
            return self.diaryService.update(entry: entry, diary: diary).map { _ in }
        }
    }
    
    var sectionedItems: Observable<[DiarySection]> {
        //Below is an Observable
        return self.diaryService.entries()
            .map { results in
                return [DiarySection(model: "Entires", items: results.toArray())]
        }
    }

    //TODO: We create an entry right here, but if we exit the next controller without a cancel or save button i.e. home button then an invalid entry is crdated
    func onCreateEntry() -> CocoaAction { //action sent to add VC to do  the right thing
        //We create a new diary item
        //If it is created then we instantiate a new AddDiaryEntryViewModel.
        //We pass along an updateCation which updates the anything in the new Diary item, and a cancel action which deletes the task item
        //This returns an Observable sequence.  We're integrating the whole create-edit procss into a single sequence
        //this completes once teh Add Diary entry Scene closese

        return CocoaAction { _ in
            return self.diaryService
                .createEntry(entry: (-1, -1, "")) //when add is pressed an entry is always created with garbage
                
                //This must be updated when everytime save is pressed
                .flatMap { entry -> Observable<Void> in
                    //Here we setup what happens when each action is executed.
                    //the execution first happens in the Add VC
                    //The Add VC then sends the action to it's VM where it was inited
                    //The view model then sends the action back here where it will be executed with the correct func
                    let addDiaryEntryViewModel = AddDiaryEntryViewModel(entry: entry,
                                                          coordinator: self.sceneCoordinator,
                                                          updateAction: self.onUpdateEntry(entry: entry),
                                                          cancelAction: self.onDelete(entry: entry))
                    return self.sceneCoordinator.transition(to: Scene.addEntry(addDiaryEntryViewModel), type: .modal)
            }
        }
    }
    
    func onCurrentPress() -> CocoaAction {
        return CocoaAction { _ in
            return self.sceneCoordinator.pop()
        }
    }
    
    lazy var editAction: Action<DiaryEntry, Void> = { this in
        return Action { entry in
            let editViewModel = AddDiaryEntryViewModel(
                entry: entry,
                coordinator: this.sceneCoordinator,
                updateAction: this.onUpdateEntry(entry: entry)
            )
            return this.sceneCoordinator.transition(to: Scene.addEntry(editViewModel), type: .modal)
        }
    }(self)
    
    lazy var deleteAction: Action<DiaryEntry, Void> = {service in
        return Action { entry in
            return service.delete(entry: entry)
        }
    }(self.diaryService)
}
