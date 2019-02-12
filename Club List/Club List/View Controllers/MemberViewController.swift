//
//  MemberViewController.swift
//  Club List
//
//  Created by Bharat Mahajan on 11/02/19.
//  Copyright © 2019 BharatMahajan. All rights reserved.
//

import UIKit
import MessageUI

protocol MemberViewDelegate: class {
    func didChangeDataFor(selectedCompanyId: String, selectedMember: Member)
}

class MemberViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchResultsUpdating,MFMailComposeViewControllerDelegate {

    @IBOutlet weak var lblSortType: UILabel!
    @IBOutlet weak var lblFilterType: UILabel!
    @IBOutlet weak var lblNoRecords: UILabel!
    @IBOutlet weak var tblMemberList: UITableView!
    var arrSearchedMemberList = [Member]()
    var arrFilteredMemberList = [Member]()
    var arrSelectedMemberList = [Member]()
    var selectedCompanyId = ""
    var resultSearchController = UISearchController()
    var isFiltered = false
    var sortAscending = true
    var sortType = 0
    var filterType = 0
    weak var delegate: MemberViewDelegate!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .automatic
        
        // Declare the searchController
        self.resultSearchController = ({
            let searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.searchBar.showsCancelButton = false
            searchController.dimsBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false
            searchController.searchBar.sizeToFit()
            self.navigationItem.searchController = searchController
            return searchController
        })()
        
        let cellMemberList = UINib(nibName: Constants.identifierMemberTableViewCell, bundle: nil)
        self.tblMemberList.register(cellMemberList, forCellReuseIdentifier: Constants.identifierMemberTableViewCell)
        self.tblMemberList.tableFooterView = UIView.init(frame: CGRect.zero)
        
        self.lblNoRecords.isHidden = true
        // Do any additional setup after loading the view.
    }

    //MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isFiltered
        {
            return self.arrFilteredMemberList.count
        }
        if self.resultSearchController.isActive
        {
            return self.arrSearchedMemberList.count
        }
        else
        {
            return self.arrSelectedMemberList.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.identifierMemberTableViewCell, for: indexPath) as! MemberTableViewCell
        cell.selectionStyle = .none
        
        cell.viewContent.layer.shadowColor = UIColor.gray.cgColor
        cell.viewContent.layer.shadowOffset = CGSize.init(width: 0.8, height: 0.8)
        cell.viewContent.layer.shadowOpacity = 0.20
        cell.viewContent.layer.shadowRadius = 1

        var memberData : Member!
        if self.isFiltered
        {
            memberData = self.arrFilteredMemberList[indexPath.row]
        }
        else
        {
            if self.resultSearchController.isActive
            {
                memberData = self.arrSearchedMemberList[indexPath.row]
            }
            else
            {
                memberData = self.arrSelectedMemberList[indexPath.row]
            }
        }
        cell.lblFirstName.text = memberData.name.first
        cell.lblLastName.text = memberData.name.last
        cell.lblAge.text = String.init(format: "%d", memberData.age)
        cell.lblMail.text = memberData.email
        cell.lblPhone.text = memberData.phone
        let lblTapGesture = UITapGestureRecognizer.init(target: self, action: #selector(tapFunction(sender:)))
        lblTapGesture.numberOfTapsRequired = 1
        lblTapGesture.name = memberData.email
        cell.lblMail.addGestureRecognizer(lblTapGesture)
        cell.lblMail.isUserInteractionEnabled = true
        cell.updateMemberCell(member: memberData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actionFavorite = self.performFavoriteActionForRowAt(indexPath: indexPath)
        let swipeCell = UISwipeActionsConfiguration(actions: [actionFavorite])
        swipeCell.performsFirstActionWithFullSwipe = true
        return swipeCell
    }

    func performFavoriteActionForRowAt(indexPath : IndexPath) -> UIContextualAction
    {
        var memberData:Member!
        if self.isFiltered
        {
            memberData = self.arrFilteredMemberList[indexPath.row]
        }
        else
        {
            if self.resultSearchController.isActive
            {
                memberData = self.arrSearchedMemberList[indexPath.row]
            }
            else
            {
                memberData = self.arrSelectedMemberList[indexPath.row]
            }
        }
        let action = UIContextualAction(style: .normal, title: "Favorite")
        { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            memberData.toggleFavorite()
            self.delegate.didChangeDataFor(selectedCompanyId: self.selectedCompanyId, selectedMember: memberData)
            if self.isFiltered
            {
                self.arrFilteredMemberList[indexPath.row] = memberData
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedMemberList[indexPath.row] = memberData
                }
                else
                {
                    self.arrSelectedMemberList[indexPath.row] = memberData
                }
            }
            if self.filterType == 1 && !memberData.favorite
            {
                if self.resultSearchController.isActive
                {
                    for (index,memberElement) in self.arrSearchedMemberList.enumerated()
                    {
                        if memberElement._id == memberData._id
                        {
                            self.arrSearchedMemberList.remove(at: index)
                            self.arrSearchedMemberList.insert(memberData, at: index)
                            break
                        }
                    }
                }
                else
                {
                    for (index,memberElement) in self.arrSelectedMemberList.enumerated()
                    {
                        if memberElement._id == memberData._id
                        {
                            self.arrSelectedMemberList.remove(at: index)
                            self.arrSelectedMemberList.insert(memberData, at: index)
                            break
                        }
                    }
                }

                if self.isFiltered
                {
                    self.arrFilteredMemberList.remove(at: indexPath.row)
                    self.tblMemberList.deleteRows(at: [indexPath], with: .none)
                }
                else
                {
                    self.tblMemberList.reloadRows(at: [indexPath], with: .none)
                }
            }
            else
            {
                self.tblMemberList.reloadRows(at: [indexPath], with: .none)
            }
            completionHandler(true)
        }
        action.title = "Favorite"
        if !memberData.favorite
        {
            action.backgroundColor = UIColor.orange
        }
        else
        {
            action.backgroundColor = UIColor.gray
        }
        return action
    }
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        let emailTitle = "Feedback"
        let messageBody = "Feature request or bug report?"
        let toRecipents = [sender.name]
        if MFMailComposeViewController.canSendMail()
        {
            let mc = MFMailComposeViewController()
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            mc.setToRecipients(toRecipents as? [String])
            mc.setMessageBody("<p>Add body</p>", isHTML: true)
            self.present(mc, animated: true, completion: nil)

        }
        else
        {
            let alert = UIAlertController(title: "", message: "Add an email account in Mails to send mail", preferredStyle: .alert)
            let action = UIAlertAction.init(title: "Ok", style: .default) { (action:UIAlertAction) in
                alert.dismiss(animated: true, completion: nil)
            }
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            print("Mail cancelled")
        case .saved:
            print("Mail saved")
        case .sent:
            print("Mail sent")
        case .failed:
            print("Mail sent failure: \(String(describing: error?.localizedDescription))")
        }
        self.dismiss(animated: true, completion: nil)
    }
    


    //MARK: - Search Results
    
    func updateSearchResults(for searchController: UISearchController) {
        if !searchController.isActive {
            if self.arrSelectedMemberList.count == 0
            {
                self.lblNoRecords.text = "No records found"
                self.lblNoRecords.isHidden = false
                self.tblMemberList.isHidden = true
            }
            else
            {
                self.tblMemberList.isHidden = false
                self.lblNoRecords.isHidden = true
            }
            self.tblMemberList.reloadData()
            return
        }
        searchController.searchBar.showsCancelButton = true
        self.arrSearchedMemberList.removeAll(keepingCapacity: false)
        let array = self.arrSelectedMemberList.filter({ (member: Member) -> Bool in
            let strMemberName = NSString.init(format: "%@ %@", member.name.first,member.name.last)
            return strMemberName.localizedCaseInsensitiveContains(searchController.searchBar.text!)
        })
        self.arrSearchedMemberList = array
        if self.arrSearchedMemberList.count == 0
        {
            self.lblNoRecords.text = "No records found"
            self.lblNoRecords.isHidden = false
            self.tblMemberList.isHidden = true
        }
        else
        {
            self.tblMemberList.isHidden = false
            self.lblNoRecords.isHidden = true
        }
        self.tblMemberList.reloadData()
    }
    
    // MARK: - Sort List
    @IBAction func sortList(_ sender: UIButton)
    {
        let sortActionSheet = UIAlertController(title: "Sort by", message: nil, preferredStyle: .actionSheet)
        
        let actionNameAsc = UIAlertAction(title: "Name ascending", style: .default) { (action:UIAlertAction) in
            if self.isFiltered
            {
                self.arrFilteredMemberList = self.sortArray(array: self.arrFilteredMemberList, isAscending: true,type: 0)
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedMemberList = self.sortArray(array: self.arrSearchedMemberList, isAscending: true,type: 0)
                }
                else
                {
                    self.arrSelectedMemberList = self.sortArray(array: self.arrSelectedMemberList, isAscending: true,type: 0)
                }
            }
            self.lblSortType.text = "Name asc"
            self.sortAscending = true
            self.sortType = 0
            self.tblMemberList.reloadData()
        }
        let actionNameDesc = UIAlertAction(title: "Name descending", style: .default) { (action:UIAlertAction) in
            if self.isFiltered
            {
                self.arrFilteredMemberList = self.sortArray(array: self.arrFilteredMemberList, isAscending: false,type: 0)
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedMemberList = self.sortArray(array: self.arrSearchedMemberList, isAscending: false,type: 0)
                }
                else
                {
                    self.arrSelectedMemberList = self.sortArray(array: self.arrSelectedMemberList, isAscending: false,type: 0)
                }
            }
            self.lblSortType.text = "Name desc"
            self.sortAscending = false
            self.sortType = 0
            self.tblMemberList.reloadData()
        }
        let actionAgeAsc = UIAlertAction(title: "Age ascending", style: .default) { (action:UIAlertAction) in
            if self.isFiltered
            {
                self.arrFilteredMemberList = self.sortArray(array: self.arrFilteredMemberList, isAscending: true,type: 1)
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedMemberList = self.sortArray(array: self.arrSearchedMemberList, isAscending: true,type: 1)
                }
                else
                {
                    self.arrSelectedMemberList = self.sortArray(array: self.arrSelectedMemberList, isAscending: true,type: 1)
                }
            }
            self.lblSortType.text = "Age asc"
            self.sortAscending = true
            self.sortType = 1
            self.tblMemberList.reloadData()
        }
        let actionAgeDesc = UIAlertAction(title: "Age descending", style: .default) { (action:UIAlertAction) in
            if self.isFiltered
            {
                self.arrFilteredMemberList = self.sortArray(array: self.arrFilteredMemberList, isAscending: false,type: 1)
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedMemberList = self.sortArray(array: self.arrSearchedMemberList, isAscending: false,type: 1)
                }
                else
                {
                    self.arrSelectedMemberList = self.sortArray(array: self.arrSelectedMemberList, isAscending: false,type: 1)
                }
            }
            self.lblSortType.text = "Age desc"
            self.sortAscending = false
            self.sortType = 1
            self.tblMemberList.reloadData()
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            sortActionSheet.dismiss(animated: true, completion: nil)
        }
        sortActionSheet.addAction(actionNameAsc)
        sortActionSheet.addAction(actionNameDesc)
        sortActionSheet.addAction(actionAgeAsc)
        sortActionSheet.addAction(actionAgeDesc)
        sortActionSheet.addAction(actionCancel)
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad ){
            sortActionSheet.popoverPresentationController?.sourceView = sender.imageView
        }
        if self.resultSearchController.isActive
        {
            self.resultSearchController.present(sortActionSheet, animated: true, completion: nil)
        }
        else
        {
            self.present(sortActionSheet, animated: true, completion: nil)
        }
    }
    
    func sortArray(array:[Member], isAscending:Bool, type:Int) -> [Member]
    {
        var sortedArray = array
        if type == 0 //name
        {
            if isAscending
            {
                sortedArray = sortedArray.sorted(by: { $0.name.first+$0.name.last
                    < $1.name.first+$0.name.last })
            }
            else
            {
                sortedArray = sortedArray.sorted(by: { $0.name.first+$0.name.last
                    > $1.name.first+$0.name.last })
            }
        }
        else // age
        {
            if isAscending
            {
                sortedArray = sortedArray.sorted(by: { $0.age < $1.age })
            }
            else
            {
                sortedArray = sortedArray.sorted(by: { $0.age > $1.age })
            }
        }
        return sortedArray
    }
    
    // MARK: - Filter List
    @IBAction func filterList(_ sender: UIButton)
    {
        let filterActionSheet = UIAlertController(title: "Filter by", message: nil, preferredStyle: .actionSheet)
        let actionAll = UIAlertAction(title: "All", style: .default) { (action:UIAlertAction) in
            self.isFiltered = false
            self.arrFilteredMemberList.removeAll(keepingCapacity: false)
            if self.arrSelectedMemberList.count == 0
            {
                self.lblNoRecords.text = "No records found"
                self.lblNoRecords.isHidden = false
                self.tblMemberList.isHidden = true
            }
            else
            {
                self.tblMemberList.isHidden = false
                self.lblNoRecords.isHidden = true
            }
            self.lblFilterType.text = "All"
            self.filterType = 0
            self.arrSelectedMemberList = self.sortArray(array: self.arrSelectedMemberList, isAscending: self.sortAscending, type: self.sortType)
            self.tblMemberList.reloadData()
        }
        let actionFavorite = UIAlertAction(title: "Favorited", style: .default) { (action:UIAlertAction) in
            self.isFiltered = true
            self.arrFilteredMemberList.removeAll(keepingCapacity: false)
            for elementMember in self.arrSelectedMemberList
            {
                if elementMember.favorite
                {
                    self.arrFilteredMemberList.append(elementMember)
                }
            }
            if self.arrFilteredMemberList.count == 0
            {
                self.lblNoRecords.text = "No records found"
                self.lblNoRecords.isHidden = false
                self.tblMemberList.isHidden = true
            }
            else
            {
                self.tblMemberList.isHidden = false
                self.lblNoRecords.isHidden = true
            }
            self.lblFilterType.text = "Favorited"
            self.filterType = 1
            self.arrFilteredMemberList = self.sortArray(array: self.arrFilteredMemberList, isAscending: self.sortAscending, type: self.sortType)
            self.tblMemberList.reloadData()
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            filterActionSheet.dismiss(animated: true, completion: nil)
        }
        filterActionSheet.addAction(actionAll)
        filterActionSheet.addAction(actionFavorite)
        filterActionSheet.addAction(actionCancel)
        if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad ){
            filterActionSheet.popoverPresentationController?.sourceView = sender.imageView
        }
        if self.resultSearchController.isActive
        {
            self.resultSearchController.present(filterActionSheet, animated: true, completion: nil)
        }
        else
        {
            self.present(filterActionSheet, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
