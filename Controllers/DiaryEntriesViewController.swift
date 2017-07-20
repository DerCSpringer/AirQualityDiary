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
    @IBOutlet weak var currentConditions: UIBarButtonItem!
    
    var viewModel: DiaryEntriesViewModel!
    let dataSource = RxTableViewSectionedAnimatedDataSource<DiarySection>()
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setEditing(true, animated: false)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        //TODO: Change row heigh based on font size
        //Allow date to wrap around
        tableView.backgroundColor = UIColor.black
        
        tableView.rx.setDelegate(self)
        .addDisposableTo(bag)

        configureDataSource()

        //This must be done before we bind observables
        //It probably starts observing only elements at time X.  If we wait until later it maybe not see stuff already in teh database
    }
    
    
    func bindViewModel() {
        viewModel.sectionedItems
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        addDiaryEntry.rx.action = viewModel.onCreateEntry()
        currentConditions.rx.action = viewModel.onCurrentPress()
        
        tableView.rx.itemDeleted
            .map { [unowned self] indexPath in
                try! self.dataSource.model(at: indexPath) as! DiaryEntry
            }
            .subscribe(viewModel.deleteAction.inputs)
            .disposed(by:bag)
        
        tableView.rx.itemSelected
            .map { [unowned self] indexPath in
                let this = try self.dataSource.model(at: indexPath) as! DiaryEntry
                return this
            }
            .subscribe(viewModel.editAction.inputs)
            .disposed(by: bag)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "DiaryEntryCell") as! DiaryEntryTableViewCell
        headerView.initWithHeaderView()
        headerView.frame = view.frame
        view.addSubview(headerView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    
    fileprivate func configureDataSource() {
        
        dataSource.canEditRowAtIndexPath = { cell in
            return true
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
