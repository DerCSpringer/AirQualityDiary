//
//  CLLocationManager+Rx.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/30/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa

class RxCLLocationManagerDelegateProxy : DelegateProxy, CLLocationManagerDelegate, DelegateProxyType {
    
    internal lazy var didUpdateLocationsSubject = PublishSubject<[CLLocation]>()
    
    class func currentDelegateFor(_ object: AnyObject) -> AnyObject? {
        let locationManager: CLLocationManager = object as! CLLocationManager
        return locationManager.delegate
    }
    
    class func setCurrentDelegate(_ delegate: AnyObject?, toObject object: AnyObject) {
        let locationManager: CLLocationManager = object as! CLLocationManager
        if let delegate = delegate {
            locationManager.delegate = (delegate as! CLLocationManagerDelegate)
        } else {
            locationManager.delegate = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        _forwardToDelegate?.locationManager(manager, didUpdateLocations: locations)
        didUpdateLocationsSubject.onNext(locations)
    }
}

extension Reactive where Base: CLLocationManager {

    var delegate: DelegateProxy {
        return RxCLLocationManagerDelegateProxy.proxyForObject(base)
    }
    
    public var didUpdateLocations: Observable<[CLLocation]> {
        return (delegate as! RxCLLocationManagerDelegateProxy).didUpdateLocationsSubject.asObservable()
    }
    
    public var didChangeAuthorizationStatus: Observable<CLAuthorizationStatus> {
        return delegate.methodInvoked(#selector(CLLocationManagerDelegate.locationManager(_:didChangeAuthorization:)))
            .map { a in
                let number = a[1] as? NSNumber
                return CLAuthorizationStatus(rawValue: Int32(number!.intValue)) ?? .notDetermined //recheck optional status
        }
    }
}
