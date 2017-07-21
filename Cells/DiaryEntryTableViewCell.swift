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
        date.lineBreakMode = .byWordWrapping
        //date.size
        //TODO: Need to allow for bigger font
        button.rx.action = action
        self.backgroundColor = UIColor.black
        let format = DateFormatter()
        format.dateFormat = "MM/dd/yyyy 'at' HH:mm"

        //Every time entry is updated our tableview Will be too, but this usually won't be necessary in the current incantation of the app
        entry.rx.observe(Int.self, "o3")
            .subscribe(onNext: { [weak self] o3 in
                if o3 == -1 {
                    self?.o3AQI.text = "N/A"
                } else {
                self?.o3AQI.text = String(o3!)
                }
            })
            .disposed(by: disposeBag)
        
        entry.rx.observe(Int.self, "pm25")
            .subscribe(onNext: { [weak self] pm25 in
                if pm25 == -1 {
                    self?.PM25AQI.text = "N/A"
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
                let image = UIImage(named: checked == false ? "itemNotChecked" : "itemChecked")
                self?.button.setImage(image, for: .normal)
            })
        .disposed(by: disposeBag)
    }
    
    override func prepareForReuse() {
        button.rx.action = nil
        disposeBag = DisposeBag()
        super.prepareForReuse()
    }
}

extension DiaryEntryTableViewCell {
    func initWithHeaderView() {
        self.o3AQI.text = "O3"
        self.PM25AQI.text = "PM 2.5"
        self.date.text = "Date of Observation"
        self.button.setTitle("Bad day?", for: .normal)
        self.button.titleLabel?.lineBreakMode = .byWordWrapping
        self.button.isUserInteractionEnabled = false
    }
}
