//
//  CurrentConditionsViewController.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/30/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class CurrentConditionsViewController: UIViewController, BindableType {
    
    typealias ColorName = (name: String, color: Observable<UIColor>)

    @IBOutlet weak var currentForcastPM: UILabel!
    @IBOutlet weak var currentForcastO3: UILabel!
    @IBOutlet weak var currentPM: UILabel!
    @IBOutlet weak var currentO3: UILabel!
    @IBOutlet weak var tomorrowO3: UILabel!
    @IBOutlet weak var tomorrowPM: UILabel!
    @IBOutlet weak var diaryEntries: UIBarButtonItem!
    
    @IBOutlet weak var pm25TodayForecastIndicator: UIActivityIndicatorView!
    @IBOutlet weak var o3CurrentIndicator: UIActivityIndicatorView!
    @IBOutlet weak var pm25CurrentIndicator: UIActivityIndicatorView!
    @IBOutlet weak var o3TomorrowForecastIndicator: UIActivityIndicatorView!
    @IBOutlet weak var pm25TomorrowForecastIndicator: UIActivityIndicatorView!
    @IBOutlet weak var o3TodayForecastIndicator: UIActivityIndicatorView!
    
    let bag = DisposeBag()
    
    var viewModel: CurrentConditionsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //hmm I want the min values for pm25 and o3 known, but not nessicarily exposed
    //Maybe I send values to a struct based upon what type and it returns a color
    
    //I want to use combine latest to have two things the color and the AQI level.  When either updates then the whole thing updates
    func bindViewModel() {
        diaryEntries.rx.action = viewModel.onEntryButtonPress()
        
        //MARK: Current forecast O3 Label and Indicator
        
        let stuff = viewModel.test.asObservable()
        .shareReplay(1)
        
        stuff

            .map{ return $0.name }
        .asDriver(onErrorJustReturn: "Unavailable")
        .drive(self.currentForcastO3.rx.text)
        .addDisposableTo(bag)
        
        //stuff.flatMap { $0.color }
        stuff.map { PolutionLevel.colorForPolutionLevel($0.level) }
        .asDriver(onErrorJustReturn: UIColor.blue)
        .drive(self.currentForcastO3.rx.textColor)
        .addDisposableTo(bag)
        
        
        
//        viewModel.currentForcastO3.asDriver()
//        .drive(currentForcastO3.rx.text)
//        .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(currentForcastO3.rx.isHidden)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(o3TodayForecastIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        //MARK: Current Forecast PM2.5 Label and Indicator

        viewModel.currentForcastPM.asDriver()
            .drive(currentForcastPM.rx.text)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(pm25TodayForecastIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(currentForcastPM.rx.isHidden)
        .addDisposableTo(bag)
        
        //MARK: Tomorrow's Forecast O3 Label and Indicator
        
        viewModel.tomorrowO3.asDriver()
            .drive(tomorrowO3.rx.text)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(o3TomorrowForecastIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(tomorrowO3.rx.isHidden)
            .addDisposableTo(bag)

        //MARK: Tomorrow's Forecast PM2.5 Label and Indicator
        
        viewModel.tomorrowPM.asDriver()
            .drive(tomorrowPM.rx.text)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(pm25TomorrowForecastIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(tomorrowPM.rx.isHidden)
            .addDisposableTo(bag)
        
        //MARK: Current Conditions O3 Label and Indicator
        
        viewModel.currentO3.asDriver()
            .drive(currentO3.rx.text)
            .addDisposableTo(bag)
        
        viewModel.currentFetchIsFetching.asDriver()
            .drive(o3CurrentIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.currentFetchIsFetching.asDriver()
            .drive(currentO3.rx.isHidden)
            .addDisposableTo(bag)

        //MARK: Current Conditions PM2.5 Label and Indicator

        viewModel.currentPM.asDriver()
            .drive(currentPM.rx.text)
            .addDisposableTo(bag)
        
        viewModel.currentFetchIsFetching.asDriver()
            .drive(pm25CurrentIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.currentFetchIsFetching.asDriver()
            .drive(currentPM.rx.isHidden)
            .addDisposableTo(bag)

    }
}
