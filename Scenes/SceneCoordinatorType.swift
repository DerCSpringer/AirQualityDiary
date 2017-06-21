//
//  SceneCoordinatorType.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import UIKit
import RxSwift

protocol SceneCoordinatorType { //Any type of scene coordinator must do these things
    init(window: UIWindow)
    
    /// transition to another scene
    @discardableResult //We don't need to use the returned type

    func transition(to scene: Scene, type: SceneTransitionType) -> Observable<Void>
    
    /// pop scene from navigation stack or dismiss current modal
    @discardableResult
    func pop(animated: Bool) -> Observable<Void>
}

extension SceneCoordinatorType {
    @discardableResult
    func pop() -> Observable<Void> {
        return pop(animated: true)
    }
}
