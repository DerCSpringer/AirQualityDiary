//
//  DiaryEntriesViewController.swift
//  AirQualityDiary
//
//  Created by Daniel Springer on 6/21/17.
//  Copyright © 2017 Daniel Springer. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import Action

class DiaryEntriesViewController: UIViewController, BindableType, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addDiaryEntry: UIBarButtonItem!
    
    var headerView: UIView?
    var viewModel: DiaryEntriesViewModel!
    let notifications = NotificationCenter.default.rx.notification(Notification.Name.UIDeviceOrientationDidChange)
    
    
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<DiarySection>()
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setEditing(true, animated: false)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        
        tableView.rx.setDelegate(self)
        .addDisposableTo(bag)
        
        notifications.subscribe(onNext: { notification in
            self.headerView?.updateConstraintsIfNeeded()
        })
        .addDisposableTo(bag)
        
        
        
        
        configureDataSource() //This must be done before we bind observables
        //It probably starts observing only elements at time X.  If we wait until later it maybe not see stuff already in teh database
    }
    
//    override func updateViewConstraints() {
//        self.headerView?.updateConstraintsIfNeeded()
//        super.updateViewConstraints()
//    }
    
    func bindViewModel() {
        
        viewModel.sectionedItems
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        addDiaryEntry.rx.action = viewModel.onCreateEntry()

    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        view.tintColor = UIColor.purple
//        let header:UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
//        header.textLabel?.textColor = UIColor.white
        
        let headerView = tableView.dequeueReusableCell(withIdentifier: "DiaryEntryCell") as! DiaryEntryTableViewCell
        //no good need to update autolayout on rotation
        headerView.o3AQI.text = "O3"
        headerView.PM25AQI.text = "PM 2.5"
        headerView.date.text = "Date of Observation"
        headerView.button.alpha = 0.0 //look for better solution
        view.addSubview(headerView)
        notifications.subscribe(onNext: { _ in
            for subview in view.subviews {
                subview.frame = view.frame
            }
        })
            .addDisposableTo(bag)
       //self.headerView = &view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    fileprivate func configureDataSource() {
        
        dataSource.canEditRowAtIndexPath = {_ in
            true
        }
        dataSource.titleForHeaderInSection = { dataSource, index in
            return ""
        }
        
        
        dataSource.configureCell = {
            [weak self] dataSource, tableView, indexPath, entry in
            let cell = tableView.dequeueReusableCell(withIdentifier: "DiaryEntryCell", for: indexPath) as! DiaryEntryTableViewCell
            if let strongSelf = self {
                cell.configure(with: entry, action: strongSelf.viewModel.onToggle(entry: entry))
                //Here we connect an Action with a cell, but we know nothing about the action nor do we set it up
                //All of that is done in the VM
                //The cell is teh one which will execute the action which notifies the VM to do appropriate action(s)
                //cell.configure(with: item, action: strongSelf.viewModel.onToggle(task: item))
            }
            return cell
        }
    }

}
