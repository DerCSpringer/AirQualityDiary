//
//  SceneTransitionType.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation

enum SceneTransitionType {
    case root       // make view controller the root view controller
    case push       // push view controller to navigation stack
    case modal      // present view controller modally
}
