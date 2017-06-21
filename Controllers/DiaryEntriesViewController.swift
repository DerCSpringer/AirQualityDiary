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

class DiaryEntriesViewController: UIViewController, BindableType {
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: DiaryEntriesViewModel!
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<DiarySection>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setEditing(true, animated: false)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        
        configureDataSource() //This must be done before we bind observables
        //It probably starts observing only elements at time X.  If we wait until later it maybe not see stuff already in teh database
    }
    
    func bindViewModel() {
        
    }
    
    fileprivate func configureDataSource() {
        
        dataSource.canEditRowAtIndexPath = {_ in
            true
        }
        dataSource.titleForHeaderInSection = { dataSource, index in
            dataSource.sectionModels[index].model
        }
        
        dataSource.configureCell = {
            [weak self] dataSource, tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: "DiaryEntryCell", for: indexPath) as! DiaryEntryTableViewCell
            if let strongSelf = self {
                //Here we connect an Action with a cell, but we know nothing about the action nor do we set it up
                //All of that is done in the VM
                //The cell is teh one which will execute the action which notifies the VM to do appropriate action(s)
                cell.configure(with: item, action: strongSelf.viewModel.onToggle(task: item))
            }
            return cell
        }
    }

}
