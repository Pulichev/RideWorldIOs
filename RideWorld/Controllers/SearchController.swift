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
   var candies = [Candy]()
   var filteredCandies = [Candy]()
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
      searchController.searchBar.scopeButtonTitles = ["All", "Chocolate", "Hard", "Other"]
      tableView.tableHeaderView = searchController.searchBar
      
      candies = [
         Candy(category:"Chocolate", name:"Chocolate Bar"),
         Candy(category:"Chocolate", name:"Chocolate Chip"),
         Candy(category:"Chocolate", name:"Dark Chocolate"),
         Candy(category:"Hard", name:"Lollipop"),
         Candy(category:"Hard", name:"Candy Cane"),
         Candy(category:"Hard", name:"Jaw Breaker"),
         Candy(category:"Other", name:"Caramel"),
         Candy(category:"Other", name:"Sour Chew"),
         Candy(category:"Other", name:"Gummi Bear")]
   }
   
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
   }
   
   // MARK: - Table View
   override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if searchController.isActive && searchController.searchBar.text != "" {
         return filteredCandies.count
      }
      return candies.count
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultsCell", for: indexPath)
      let candy: Candy
      if searchController.isActive && searchController.searchBar.text != "" {
         candy = filteredCandies[indexPath.row]
      } else {
         candy = candies[indexPath.row]
      }
      cell.textLabel!.text = candy.name
      cell.detailTextLabel!.text = candy.category
      return cell
   }
   
   func filterContentForSearchText(_ searchText: String, scope: String = "All") {
      filteredCandies = candies.filter({( candy : Candy) -> Bool in
         let categoryMatch = (scope == "All") || (candy.category == scope)
         return categoryMatch && candy.name.lowercased().contains(searchText.lowercased())
      })
      tableView.reloadData()
   }
}

extension SearchController: UISearchBarDelegate {
   // MARK: - UISearchBar Delegate
   func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
      filterContentForSearchText(searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
   }
}

extension SearchController: UISearchResultsUpdating {
   // MARK: - UISearchResultsUpdating Delegate
   func updateSearchResults(for searchController: UISearchController) {
      let searchBar = searchController.searchBar
      let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
      filterContentForSearchText(searchController.searchBar.text!, scope: scope)
   }
}

import Foundation

struct Candy {
   let category : String
   let name : String
}
