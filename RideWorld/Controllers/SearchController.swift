//
//  SearchController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 16.06.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class SearchController: UITableViewController {
   
   // MARK: - Properties
   var riders = [UserItem]()
   var spots = [SpotItem]()
   
   let searchController = UISearchController(searchResultsController: nil)
   
   // MARK: - View Setup
   override func viewDidLoad() {
      super.viewDidLoad()
      
      // Setup the Search Controller
      searchController.searchResultsUpdater = self
      searchController.searchBar.delegate = self
      definesPresentationContext = true
      searchController.dimsBackgroundDuringPresentation = false
      
      // Setup the Scope Bar
      searchController.searchBar.scopeButtonTitles = ["Riders", "Spots"]
      tableView.tableHeaderView = searchController.searchBar
   }
   
   // MARK: - Table View
   override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return riders.count
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultsCell", for: indexPath)
      
      let row = indexPath.row
      
      let rider = riders[row]
      
      cell.textLabel!.text = rider.login
      cell.detailTextLabel!.text = rider.nameAndSename
      
      return cell
   }
   
   func filterContentForSearchText(_ searchText: String, scope: String = "Riders") {
      UserModel.searchUsersWithLogin(startedWith: searchText) { users in
         self.riders = users
         
         self.tableView.reloadData()
      }
   }
}

extension SearchController: UISearchBarDelegate {
   // MARK: - UISearchBar Delegate
   func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
      if searchController.isActive && searchController.searchBar.text != "" {
         filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
      }
   }
}

extension SearchController: UISearchResultsUpdating {
   // MARK: - UISearchResultsUpdating Delegate
   func updateSearchResults(for searchController: UISearchController) {
      if searchController.isActive && searchController.searchBar.text != "" {
         let searchBar = searchController.searchBar
         let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
         filterContentForSearchText(searchController.searchBar.text!, scope: scope)
      }
   }
}
