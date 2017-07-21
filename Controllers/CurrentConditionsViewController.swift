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
    
    private let bag = DisposeBag()
    
    var viewModel: CurrentConditionsViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func bindViewModel() {
        diaryEntries.rx.action = viewModel.onEntryButtonPress()
        
        //MARK: Current forecast O3 Label and Indicator
        
        let currentForecastO3 = viewModel.currentForecastO3.asObservable()
        .shareReplay(1)
        
        currentForecastO3
        .map{ return $0.AQI }
        .asDriver(onErrorJustReturn: "Unavailable")
        .drive(self.currentForcastO3.rx.text)
        .addDisposableTo(bag)
        
        currentForecastO3.map { PollutionLevel.colorForPollutionLevel($0.level) }
        .asDriver(onErrorJustReturn: UIColor.blue)
        .drive(self.currentForcastO3.rx.textColor)
        .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(currentForcastO3.rx.isHidden)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(o3TodayForecastIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        //MARK: Current Forecast PM2.5 Label and Indicator

        let currentForecastPM = viewModel.currentForcastPM.asObservable()
            .shareReplay(1)
        
        currentForecastPM
            .map{ return $0.AQI }
            .asDriver(onErrorJustReturn: "Unavailable")
            .drive(self.currentForcastPM.rx.text)
            .addDisposableTo(bag)
        
        currentForecastPM.map { PollutionLevel.colorForPollutionLevel($0.level) }
            .asDriver(onErrorJustReturn: UIColor.blue)
            .drive(self.currentForcastPM.rx.textColor)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(pm25TodayForecastIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(currentForcastPM.rx.isHidden)
        .addDisposableTo(bag)
        
        //MARK: Tomorrow's Forecast O3 Label and Indicator
        
        let o3Tomorrow = viewModel.tomorrowO3.asObservable()
            .shareReplay(1)
        
        o3Tomorrow
            .map{ return $0.AQI }
            .asDriver(onErrorJustReturn: "Unavailable")
            .drive(self.tomorrowO3.rx.text)
            .addDisposableTo(bag)
        
        o3Tomorrow.map { PollutionLevel.colorForPollutionLevel($0.level) }
            .asDriver(onErrorJustReturn: UIColor.blue)
            .drive(self.tomorrowO3.rx.textColor)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(o3TomorrowForecastIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(tomorrowO3.rx.isHidden)
            .addDisposableTo(bag)

        //MARK: Tomorrow's Forecast PM2.5 Label and Indicator
        
        let pmTomorrow = viewModel.tomorrowPM.asObservable()
            .shareReplay(1)
        
        pmTomorrow
            .map{ return $0.AQI }
            .asDriver(onErrorJustReturn: "Unavailable")
            .drive(self.tomorrowPM.rx.text)
            .addDisposableTo(bag)
        
        pmTomorrow.map { PollutionLevel.colorForPollutionLevel($0.level) }
            .asDriver(onErrorJustReturn: UIColor.blue)
            .drive(self.tomorrowPM.rx.textColor)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(pm25TomorrowForecastIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.forecastFetchIsFetching.asDriver()
            .drive(tomorrowPM.rx.isHidden)
            .addDisposableTo(bag)
        
        //MARK: Current Conditions O3 Label and Indicator
        
        let o3Current = viewModel.currentO3.asObservable()
            .shareReplay(1)
        
        o3Current
            .map{ return $0.AQI }
            .asDriver(onErrorJustReturn: "Unavailable")
            .drive(self.currentO3.rx.text)
            .addDisposableTo(bag)
        
        o3Current.map { PollutionLevel.colorForPollutionLevel($0.level) }
            .asDriver(onErrorJustReturn: UIColor.blue)
            .drive(self.currentO3.rx.textColor)
            .addDisposableTo(bag)
        
        viewModel.currentFetchIsFetching.asDriver()
            .drive(o3CurrentIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.currentFetchIsFetching.asDriver()
            .drive(currentO3.rx.isHidden)
            .addDisposableTo(bag)

        //MARK: Current Conditions PM2.5 Label and Indicator

        let pmCurrent = viewModel.currentPM.asObservable()
            .shareReplay(1)
        
        pmCurrent
            .map{ return $0.AQI }
            .asDriver(onErrorJustReturn: "Unavailable")
            .drive(self.currentPM.rx.text)
            .addDisposableTo(bag)
        
        pmCurrent.map { PollutionLevel.colorForPollutionLevel($0.level) }
            .asDriver(onErrorJustReturn: UIColor.blue)
            .drive(self.currentPM.rx.textColor)
            .addDisposableTo(bag)
        
        viewModel.currentFetchIsFetching.asDriver()
            .drive(pm25CurrentIndicator.rx.isAnimating)
            .addDisposableTo(bag)
        
        viewModel.currentFetchIsFetching.asDriver()
            .drive(currentPM.rx.isHidden)
            .addDisposableTo(bag)

    }
}
