//
//  CompanyViewController.swift
//  Club List
//
//  Created by Bharat Mahajan on 11/02/19.
//  Copyright © 2019 BharatMahajan. All rights reserved.
//

import UIKit
import SafariServices

class CompanyViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchResultsUpdating,MemberViewDelegate {
    
    @IBOutlet weak var lblSortType: UILabel!
    @IBOutlet weak var lblFilterType: UILabel!
    @IBOutlet weak var lblNoRecords: UILabel!
    @IBOutlet weak var viewLoader: UIView!
    @IBOutlet weak var tblCompanyList: UITableView!
    var arrCompanyList = [Company]()
    var arrFilteredCompanyList = [Company]()
    var arrSearchedCompanyList = [Company]()
    var arrSelectedMemberList = [Member]()
    var resultSearchController = UISearchController()
    var selectedCompanyId = ""
    var selectedCompanyTitle = ""
    var isFiltered = false
    let refreshControl = UIRefreshControl()
    var networkClass = NetworkClass()
    var sortAscending = true
    var filterType = 0
    // 0 - Follow 1- Favorite 2- Follow and Favorite
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .automatic
        
        refreshControl.addTarget(self, action: #selector(refreshCompanyList(_:)), for: .valueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")

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

        let cellCompanyList = UINib(nibName: Constants.identifierCompanyTableViewCell, bundle: nil)
        self.tblCompanyList.register(cellCompanyList, forCellReuseIdentifier: Constants.identifierCompanyTableViewCell)
        self.tblCompanyList.tableFooterView = UIView.init(frame: CGRect.zero)
        self.tblCompanyList.refreshControl = refreshControl
        networkClass = NetworkClass.sharedInstance
        networkClass.session = URLSession.shared
        networkClass.cache = NSCache()
        
        self.viewLoader.isHidden = true
        self.lblNoRecords.isHidden = true
        fetchCompanyList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }

    //MARK: - Network call
    @objc private func refreshCompanyList(_ sender: Any) {
        fetchCompanyList()
    }
    
    func fetchCompanyList()
    {
        self.viewLoader.isHidden = false
        NetworkClass.fetchCompanyList { (resultObj1, resultSuccess) in
            let success = resultSuccess
            if success
            {
                let resultData = resultObj1 as! [Company]
                self.arrCompanyList = resultData
                DispatchQueue.main.async {
                    if self.arrCompanyList.count == 0
                    {
                        self.lblNoRecords.text = "No records found"
                        self.lblNoRecords.isHidden = false
                        self.tblCompanyList.isHidden = true
                    }
                    else
                    {
                        self.tblCompanyList.isHidden = false
                        self.lblNoRecords.isHidden = true
                    }
                    self.viewLoader.isHidden = true
                    self.tblCompanyList.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            else
            {
                DispatchQueue.main.async {
                    self.lblNoRecords.isHidden = false
                    self.lblNoRecords.text = "Unable to fetch records"
                    self.viewLoader.isHidden = true
                    self.tblCompanyList.isHidden = true
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }

    //MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isFiltered
        {
            return self.arrFilteredCompanyList.count
        }
        if self.resultSearchController.isActive
        {
            return self.arrSearchedCompanyList.count
        }
        else
        {
            return self.arrCompanyList.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 260
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.identifierCompanyTableViewCell, for: indexPath) as! CompanyTableViewCell
        cell.selectionStyle = .none
        
        cell.viewContent.layer.shadowColor = UIColor.gray.cgColor
        cell.viewContent.layer.shadowOffset = CGSize.init(width: 0.8, height: 0.8)
        cell.viewContent.layer.shadowOpacity = 0.20
        cell.viewContent.layer.shadowRadius = 1

        var companyData : Company!
        if self.isFiltered
        {
            companyData = self.arrFilteredCompanyList[indexPath.row]
        }
        else
        {
            if self.resultSearchController.isActive
            {
                companyData = self.arrSearchedCompanyList[indexPath.row]
            }
            else
            {
                companyData = self.arrCompanyList[indexPath.row]
            }
        }
        cell.lblName.text = companyData.company
        cell.lblWebsite.text = companyData.website
        let lblTapGesture = UITapGestureRecognizer.init(target: self, action: #selector(tapFunction(sender:)))
        lblTapGesture.numberOfTapsRequired = 1
        lblTapGesture.name = companyData.website
        cell.lblWebsite.addGestureRecognizer(lblTapGesture)
        cell.lblWebsite.isUserInteractionEnabled = true
        cell.txtDescription.text = companyData.about
        cell.txtDescription.isUserInteractionEnabled = false
        cell.updateCompanyCell(company: companyData)
        cell.activityIndicatorCompanyLogo.startAnimating()
        cell.activityIndicatorCompanyLogo.isHidden = false
        if networkClass.cache.object(forKey: companyData.logo as AnyObject) != nil
        {
            cell.activityIndicatorCompanyLogo.stopAnimating()
            cell.imgLogo.image = networkClass.cache.object(forKey: companyData.logo as AnyObject) as? UIImage
        }
        else{
            NetworkClass.fetchCompanyLogoFor(strLogo: companyData.logo) { (resultData, success) in
                if success
                {
                    let data = resultData as! Data
                    DispatchQueue.main.async(execute: { () -> Void in
                        if let updateCell = self.tblCompanyList.cellForRow(at: indexPath) as! CompanyTableViewCell?  {
                            let img:UIImage! = UIImage(data: data)
                            updateCell.activityIndicatorCompanyLogo.stopAnimating()
                            updateCell.imgLogo?.image = img
                            self.networkClass.cache.setObject(img, forKey: companyData.logo as AnyObject)
                        }
                    })
                }
                else
                {
                    DispatchQueue.main.async(execute: { () -> Void in
                        if let updateCell = self.tblCompanyList.cellForRow(at: indexPath) as? CompanyTableViewCell
                        {
                            updateCell.activityIndicatorCompanyLogo.stopAnimating()
                            updateCell.imgLogo.image = #imageLiteral(resourceName: "logo_not_found")
                            self.networkClass.cache.removeObject(forKey: companyData.logo as AnyObject)
                        }
                    })
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.isFiltered
        {
            self.arrSelectedMemberList = self.arrFilteredCompanyList[indexPath.row].members
            self.selectedCompanyId = self.arrFilteredCompanyList[indexPath.row]._id
            self.selectedCompanyTitle = self.arrFilteredCompanyList[indexPath.row].company
        }
        else
        {
            if self.resultSearchController.isActive
            {
                self.arrSelectedMemberList = self.arrSearchedCompanyList[indexPath.row].members
                self.selectedCompanyId = self.arrSearchedCompanyList[indexPath.row]._id
                self.selectedCompanyTitle = self.arrSearchedCompanyList[indexPath.row].company
            }
            else
            {
                self.arrSelectedMemberList = self.arrCompanyList[indexPath.row].members
                self.selectedCompanyId = self.arrCompanyList[indexPath.row]._id
                self.selectedCompanyTitle = self.arrCompanyList[indexPath.row].company
            }
        }
        if self.arrSelectedMemberList.count != 0
        {
            showMemberViewController()
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actionFollow = self.performFollowActionForRowAt(indexPath: indexPath)
        let swipeCell = UISwipeActionsConfiguration(actions: [actionFollow])
        swipeCell.performsFirstActionWithFullSwipe = true
        return swipeCell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actionFavorite = self.performFavoriteActionForRowAt(indexPath: indexPath)
        let swipeCell = UISwipeActionsConfiguration(actions: [actionFavorite])
        swipeCell.performsFirstActionWithFullSwipe = true
        return swipeCell
    }
    
    func performFollowActionForRowAt(indexPath : IndexPath) -> UIContextualAction
    {
        var companyData:Company!
        if self.isFiltered
        {
            companyData = self.arrFilteredCompanyList[indexPath.row]
        }
        else
        {
            if self.resultSearchController.isActive
            {
                    companyData = self.arrSearchedCompanyList[indexPath.row]
            }
            else
            {
                companyData = self.arrCompanyList[indexPath.row]
            }
        }
        let action = UIContextualAction(style: .normal, title: "Follow")
        { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            companyData.toggleFollow()
            self.updateCompanyList(companyData: companyData)
            if self.isFiltered
            {
                self.arrFilteredCompanyList[indexPath.row] = companyData
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedCompanyList[indexPath.row] = companyData
                }
                else
                {
                    self.arrCompanyList[indexPath.row] = companyData
                }
            }
            if (self.filterType == 0 || self.filterType == 2) && !companyData.follow
            {
                if self.resultSearchController.isActive
                {
                    for (index,companyElement) in self.arrSearchedCompanyList.enumerated()
                    {
                        if companyElement._id == companyData._id
                        {
                            self.arrSearchedCompanyList.remove(at: index)
                            self.arrSearchedCompanyList.insert(companyData, at: index)
                            break
                        }
                    }
                }
                else
                {
                    for (index,companyElement) in self.arrCompanyList.enumerated()
                    {
                        if companyElement._id == companyData._id
                        {
                            self.arrCompanyList.remove(at: index)
                            self.arrCompanyList.insert(companyData, at: index)
                            break
                        }
                    }
                }
                if self.isFiltered
                {
                    self.arrFilteredCompanyList.remove(at: indexPath.row)
                    self.tblCompanyList.deleteRows(at: [indexPath], with: .none)
                }
                else
                {
                    self.tblCompanyList.reloadRows(at: [indexPath], with: .none)
                }
            }
            else
            {
                self.tblCompanyList.reloadRows(at: [indexPath], with: .none)
            }
            completionHandler(true)
        }
        action.title = "Follow"
        if !companyData.follow
        {
            action.backgroundColor = UIColor.blue
        }
        else
        {
            action.backgroundColor = UIColor.gray
        }
        return action
    }
    
    func performFavoriteActionForRowAt(indexPath : IndexPath) -> UIContextualAction
    {
        var companyData:Company!
        if self.isFiltered
        {
            companyData = self.arrFilteredCompanyList[indexPath.row]
        }
        else
        {
            if self.resultSearchController.isActive
            {
                companyData = self.arrSearchedCompanyList[indexPath.row]
            }
            else
            {
                companyData = self.arrCompanyList[indexPath.row]
            }
        }
        let action = UIContextualAction(style: .normal, title: "Favorite")
        { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
            companyData.toggleFavorite()
            self.updateCompanyList(companyData: companyData)
            if self.isFiltered
            {
                self.arrFilteredCompanyList[indexPath.row] = companyData
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedCompanyList[indexPath.row] = companyData
                }
                else
                {
                    self.arrCompanyList[indexPath.row] = companyData
                }
            }
            if (self.filterType == 1 || self.filterType == 2) && !companyData.favorite
            {
                
                if self.resultSearchController.isActive
                {
                    for (index,companyElement) in self.arrSearchedCompanyList.enumerated()
                    {
                        if companyElement._id == companyData._id
                        {
                            self.arrSearchedCompanyList.remove(at: index)
                            self.arrSearchedCompanyList.insert(companyData, at: index)
                            break
                        }
                    }
                }
                else
                {
                    for (index,companyElement) in self.arrCompanyList.enumerated()
                    {
                        if companyElement._id == companyData._id
                        {
                            self.arrCompanyList.remove(at: index)
                            self.arrCompanyList.insert(companyData, at: index)
                            break
                        }
                    }
                }
                if self.isFiltered
                {
                    self.arrFilteredCompanyList.remove(at: indexPath.row)
                    self.tblCompanyList.deleteRows(at: [indexPath], with: .none)
                }
                else
                {
                    self.tblCompanyList.reloadRows(at: [indexPath], with: .none)
                }
            }
            else
            {
                self.tblCompanyList.reloadRows(at: [indexPath], with: .none)
            }
            completionHandler(true)
        }
        action.title = "Favorite"
        if !companyData.favorite
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
        if !(sender.name! as NSString).localizedCaseInsensitiveContains("http")
        {
            sender.name = "https://"+sender.name!
        }
        guard let url = URL(string: sender.name!) else { return }
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
    }
    
    //MARK: - Search Results
    
    func updateSearchResults(for searchController: UISearchController) {
        if !searchController.isActive {
            if self.arrCompanyList.count == 0
            {
                self.lblNoRecords.text = "No records found"
                self.lblNoRecords.isHidden = false
                self.tblCompanyList.isHidden = true
            }
            else
            {
                self.tblCompanyList.isHidden = false
                self.lblNoRecords.isHidden = true
            }
            self.tblCompanyList.reloadData()
            return
        }
        searchController.searchBar.showsCancelButton = true
        self.arrSearchedCompanyList.removeAll(keepingCapacity: false)
        let array = self.arrCompanyList.filter({ (company: Company) -> Bool in
            let strCompanyName = company.company as NSString
            return strCompanyName.localizedCaseInsensitiveContains(searchController.searchBar.text!)
        })
        self.arrSearchedCompanyList = array
        if self.arrSearchedCompanyList.count == 0
        {
            self.lblNoRecords.text = "No records found"
            self.lblNoRecords.isHidden = false
            self.tblCompanyList.isHidden = true
        }
        else
        {
            self.tblCompanyList.isHidden = false
            self.lblNoRecords.isHidden = true
        }
        self.tblCompanyList.reloadData()
    }
    
    //MARK: - Sort List

    @IBAction func sortList(_ sender: UIButton)
    {
        let sortActionSheet = UIAlertController(title: "Sort by", message: nil, preferredStyle: .actionSheet)
        
        let actionNameAsc = UIAlertAction(title: "Name ascending", style: .default) { (action:UIAlertAction) in
            if self.isFiltered
            {
                self.arrFilteredCompanyList = self.sortArray(array: self.arrFilteredCompanyList, isAscending: true)
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedCompanyList = self.sortArray(array: self.arrSearchedCompanyList, isAscending: true)
                }
                else
                {
                    self.arrCompanyList = self.sortArray(array: self.arrCompanyList, isAscending: true)
                }
            }
            self.lblSortType.text = "Name asc"
            self.sortAscending = true
            self.tblCompanyList.reloadData()
        }
        let actionNameDesc = UIAlertAction(title: "Name descending", style: .default) { (action:UIAlertAction) in
            if self.isFiltered
            {
                self.arrFilteredCompanyList = self.sortArray(array: self.arrFilteredCompanyList, isAscending: false)
            }
            else
            {
                if self.resultSearchController.isActive
                {
                    self.arrSearchedCompanyList = self.sortArray(array: self.arrSearchedCompanyList, isAscending: false)
                }
                else
                {
                    self.arrCompanyList = self.sortArray(array: self.arrCompanyList, isAscending: false)
                }
            }
            self.lblSortType.text = "Name desc"
            self.sortAscending = false
            self.tblCompanyList.reloadData()
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            sortActionSheet.dismiss(animated: true, completion: nil)
        }
        sortActionSheet.addAction(actionNameAsc)
        sortActionSheet.addAction(actionNameDesc)
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
    
    func sortArray(array:[Company], isAscending:Bool) -> [Company]
    {
        var sortedArray = array
        if isAscending
        {
            sortedArray = sortedArray.sorted(by: { $0.company < $1.company })
        }
        else
        {
            sortedArray = sortedArray.sorted(by: { $0.company > $1.company })
        }
        return sortedArray
    }
    
    //MARK: - Filter List

    @IBAction func filterList(_ sender: UIButton)
    {
        let filterActionSheet = UIAlertController(title: "Filter by", message: nil, preferredStyle: .actionSheet)
        let actionAll = UIAlertAction(title: "All", style: .default) { (action:UIAlertAction) in
            self.isFiltered = false
            self.arrFilteredCompanyList.removeAll(keepingCapacity: false)
            if self.arrCompanyList.count == 0
            {
                self.lblNoRecords.text = "No records found"
                self.lblNoRecords.isHidden = false
                self.tblCompanyList.isHidden = true
            }
            else
            {
                self.tblCompanyList.isHidden = false
                self.lblNoRecords.isHidden = true
            }
            self.lblFilterType.text = "All"
            self.arrCompanyList = self.sortArray(array: self.arrCompanyList, isAscending: self.sortAscending)
            self.tblCompanyList.reloadData()
        }
        let actionFollow = UIAlertAction(title: "Followed", style: .default) { (action:UIAlertAction) in
            self.isFiltered = true
            self.arrFilteredCompanyList.removeAll(keepingCapacity: false)
            for elementCompany in self.arrCompanyList
            {
                if elementCompany.follow
                {
                    self.arrFilteredCompanyList.append(elementCompany)
                }
            }
            if self.arrFilteredCompanyList.count == 0
            {
                self.lblNoRecords.text = "No records found"
                self.lblNoRecords.isHidden = false
                self.tblCompanyList.isHidden = true
            }
            else
            {
                self.tblCompanyList.isHidden = false
                self.lblNoRecords.isHidden = true
            }
            self.lblFilterType.text = "Followed"
            self.arrFilteredCompanyList = self.sortArray(array: self.arrFilteredCompanyList, isAscending: self.sortAscending)
            self.filterType = 0
            self.tblCompanyList.reloadData()
        }
        let actionFavorite = UIAlertAction(title: "Favorited", style: .default) { (action:UIAlertAction) in
            self.isFiltered = true
            self.arrFilteredCompanyList.removeAll(keepingCapacity: false)
            for elementCompany in self.arrCompanyList
            {
                if elementCompany.favorite
                {
                    self.arrFilteredCompanyList.append(elementCompany)
                }
            }
            if self.arrFilteredCompanyList.count == 0
            {
                self.lblNoRecords.text = "No records found"
                self.lblNoRecords.isHidden = false
                self.tblCompanyList.isHidden = true
            }
            else
            {
                self.tblCompanyList.isHidden = false
                self.lblNoRecords.isHidden = true
            }

            self.lblFilterType.text = "Favorited"
            self.filterType = 1
            self.arrFilteredCompanyList = self.sortArray(array: self.arrFilteredCompanyList, isAscending: self.sortAscending)
            self.tblCompanyList.reloadData()
        }
        let actionFollowFavorite = UIAlertAction(title: "Followed and Favorited", style: .default) { (action:UIAlertAction) in
            self.isFiltered = true
            self.arrFilteredCompanyList.removeAll(keepingCapacity: false)
            for elementCompany in self.arrCompanyList
            {
                if elementCompany.follow && elementCompany.favorite
                {
                    self.arrFilteredCompanyList.append(elementCompany)
                }
            }
            if self.arrFilteredCompanyList.count == 0
            {
                self.lblNoRecords.text = "No records found"
                self.lblNoRecords.isHidden = false
                self.tblCompanyList.isHidden = true
            }
            else
            {
                self.tblCompanyList.isHidden = false
                self.lblNoRecords.isHidden = true
            }

            self.lblFilterType.text = "Followed and Favorited"
            self.filterType = 2
            self.arrFilteredCompanyList = self.sortArray(array: self.arrFilteredCompanyList, isAscending: self.sortAscending)
            self.tblCompanyList.reloadData()
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            filterActionSheet.dismiss(animated: true, completion: nil)
        }
        filterActionSheet.addAction(actionAll)
        filterActionSheet.addAction(actionFollow)
        filterActionSheet.addAction(actionFavorite)
        filterActionSheet.addAction(actionFollowFavorite)
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
    
    // MARK: - Member List Updates
    
    func didChangeDataFor(selectedCompanyId: String, selectedMember: Member)
    {
        var selectedCompanyList:[Company]!
        var selectedCompany:Company? = nil
        if self.isFiltered
        {
            selectedCompanyList = self.arrFilteredCompanyList
        }
        else
        {
            if self.resultSearchController.isActive
            {
                selectedCompanyList = self.arrSearchedCompanyList
            }
            else
            {
                selectedCompanyList = self.arrCompanyList
            }
        }
        
        for companyElement in selectedCompanyList
        {
            if companyElement._id == selectedCompanyId
            {
                selectedCompany = companyElement
                break
            }
        }
        
        for (index,memberElement) in (selectedCompany?.members.enumerated())!
        {
            if memberElement._id == selectedMember._id
            {
                selectedCompany?.members.remove(at: index)
                selectedCompany?.members.insert(selectedMember, at: index)
                break
            }
        }
        if selectedCompany != nil
        {
            self.updateCompanyList(companyData: selectedCompany!)
        }
        
    }
    
    func updateCompanyList(companyData : Company)
    {
        for (index,companyElement) in self.arrCompanyList.enumerated()
        {
            if companyElement._id == companyData._id
            {
                self.arrCompanyList.remove(at: index)
                self.arrCompanyList.insert(companyData, at: index)
                break
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    func showMemberViewController() {
        performSegue(withIdentifier: Constants.segueIdMemberViewController, sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.segueIdMemberViewController {
            if let destinationVC = segue.destination as? MemberViewController {
                destinationVC.arrSelectedMemberList = self.arrSelectedMemberList
                destinationVC.selectedCompanyId = self.selectedCompanyId
                destinationVC.delegate = self
                destinationVC.title = self.selectedCompanyTitle
            }
        }
    }
}
