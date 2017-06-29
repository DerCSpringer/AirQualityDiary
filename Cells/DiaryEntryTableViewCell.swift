//
//  DiaryEntryTableViewCell.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import UIKit
import Action
import RxSwift

class DiaryEntryTableViewCell: UITableViewCell {
    
    var disposeBag = DisposeBag()
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var o3AQI: UILabel!
    @IBOutlet weak var PM25AQI: UILabel!
    @IBOutlet weak var date: UILabel!
    
    func configure(with entry: DiaryEntry, action: CocoaAction) {
        button.rx.action = action
        let format = DateFormatter()
        format.dateFormat = "MM/dd/yyyy 'at' HH:mm"

        //Every time item is updated our tableview Will be too, but this usually won't be necessary in the current incantation of the app
        entry.rx.observe(Int.self, "o3")
            .subscribe(onNext: { [weak self] o3 in
                if o3 == -1 {
                    self?.o3AQI.text = "Unv"
                } else {
                self?.o3AQI.text = String(o3!)
                }
            })
            .disposed(by: disposeBag)
        
        entry.rx.observe(Int.self, "pm25")
            .subscribe(onNext: { [weak self] pm25 in
                if pm25 == -1 {
                    self?.PM25AQI.text = "Unv"
                } else {
                self?.PM25AQI.text = String(pm25!)
                }
            })
            .disposed(by: disposeBag)
        
        entry.rx.observe(Date.self, "added")
            .subscribe(onNext: { [weak self] date in
                let formattedDate = format.string(from: date!)
                self?.date.text = String(formattedDate)
            })
            .disposed(by: disposeBag)
        
        entry.rx.observe(Bool.self, "checked")
            .subscribe(onNext: { [weak self] checked in
                if checked! {
                    self?.button.setTitle("C", for: .normal)
                }
                else {
                    self?.button.setTitle("UC", for: .normal)
                }
            })
        .disposed(by: disposeBag)
    }
    
    //TODO: setup button graphics
    
    override func prepareForReuse() {
        button.rx.action = nil
        disposeBag = DisposeBag()
        super.prepareForReuse()
    }
    
}
