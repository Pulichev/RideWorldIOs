//
//  SearchController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 16.06.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher

class SearchController: UITableViewController {
  
  var riders         = [UserItem]()
  var filteredRiders = [UserItem]()
  var spots          = [SpotItem]()
  var filteredSpots  = [SpotItem]()
  
  let searchController = UISearchController(searchResultsController: nil)
  var selectedScope = NSLocalizedString("Riders", comment: "") // default value is "Riders"
  
  // MARK: - View Setup
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup the Search Controller
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    definesPresentationContext = true
    searchController.dimsBackgroundDuringPresentation = false
    searchController.searchBar.autocapitalizationType = .words
    tableView.emptyDataSetDelegate = self
    tableView.emptyDataSetSource = self
    
    // Setup the Scope Bar
    searchController.searchBar.scopeButtonTitles = [NSLocalizedString("Riders", comment: ""),
                                                    NSLocalizedString("Spots", comment: "")]
    tableView.tableHeaderView = searchController.searchBar
    tableView.tableFooterView = UIView() // deleting empty rows
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationItem.title = NSLocalizedString("Search", comment: "")
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    searchController.isActive = false
  }
  
  // MARK: - Table View filling part
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch selectedScope {
    case NSLocalizedString("Riders", comment: ""):
      return filteredRiders.count
      
    case NSLocalizedString("Spots", comment: ""):
      return filteredSpots.count
      
    default: return 0
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 44
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultsCell", for: indexPath) as! SearchResultsCell
    
    let row = indexPath.row
    
    switch selectedScope {
    case NSLocalizedString("Riders", comment: ""):
      let rider = filteredRiders[row]
      
      if rider.photo90ref != nil {
        let riderProfilePhotoURL = URL(string: rider.photo90ref!)
        
        cell.photo.kf.setImage(with: riderProfilePhotoURL)
      } else {
        cell.photo.image = UIImage(named: "noProfilePhoto")
      }
      
      cell.name!.text = rider.login
      
    case NSLocalizedString("Spots", comment: ""):
      let spot = filteredSpots[row]
      
      if spot.mainPhotoRef != nil {
        let spotPhotoURL = URL(string: spot.mainPhotoRef)
        
        cell.photo.kf.setImage(with: spotPhotoURL)
      }
      cell.name!.text = spot.name
      
    default: break
    }
    
    return cell
  }
  
  var spotDetailsForSendingToSpotInfoController: SpotItem!
  var riderItemForSending: UserItem!
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let row = indexPath.row
    
    if selectedScope == NSLocalizedString("Spots", comment: "") {
      spotDetailsForSendingToSpotInfoController = self.filteredSpots[row]
      self.performSegue(withIdentifier: "fromSearchToSpotInfo", sender: self)
    } else { // Riders
      let selectedRider = self.filteredRiders[row]
      
      if selectedRider.uid == UserModel.getCurrentUserId() {
        self.performSegue(withIdentifier: "fromSearchToUserProfile", sender: self)
      } else {
        self.riderItemForSending = selectedRider
        self.performSegue(withIdentifier: "fromSearchToRiderProfile", sender: self)
      }
    }
  }
  
  func filterContentForSearchText(_ searchText: String) {
    let lowerCasedSearchText = searchText.lowercased()
    let upperCasedSearchText = searchText.uppercased()
    
    switch self.selectedScope {
    case NSLocalizedString("Riders", comment: ""):
      if searchText.characters.count == 1 && tableView.numberOfRows(inSection: 0) == 0 {
        // get items from db where 1st symbol is entered character
        UserModel.searchUsersWithLogin(startedWith: searchText) { users in // original
          // if typed "o", also search "O". And vice versa
          if String.isLowercase(string: searchText) {
            UserModel.searchUsersWithLogin(startedWith: upperCasedSearchText) { usersToAppend in
              self.riders = users
              self.filteredRiders = users
              self.riders.append(contentsOf: usersToAppend)
              self.filteredRiders.append(contentsOf: usersToAppend)
              
              self.tableView.reloadData()
            }
          } else {
            UserModel.searchUsersWithLogin(startedWith: lowerCasedSearchText) { usersToAppend in
              self.riders = users
              self.filteredRiders = users
              self.riders.append(contentsOf: usersToAppend)
              self.filteredRiders.append(contentsOf: usersToAppend)
              
              self.tableView.reloadData()
            }
          }
        }
      } else {
        // filter items from already downloaded from db
        filteredRiders = riders.filter { $0.login.hasPrefix(searchText) }
        
        if String.isLowercase(string: searchText) {
          filteredRiders.append(contentsOf: riders.filter { $0.login.hasPrefix(upperCasedSearchText) })
        } else {
          filteredRiders.append(contentsOf: riders.filter { $0.login.hasPrefix(lowerCasedSearchText) })
        }
        
        self.tableView.reloadData()
      }
      
    case NSLocalizedString("Spots", comment: ""):
      if searchText.characters.count == 1 && tableView.numberOfRows(inSection: 0) == 0 {
        // get items from db where 1st symbol is entered character
        Spot.searchSpotsWithName(startedWith: searchText) { spots in // original
          // if typed "o", also search "O". And vice versa
          if String.isLowercase(string: searchText) {
            Spot.searchSpotsWithName(startedWith: upperCasedSearchText) { spotsToAppend in
              self.spots = spots
              self.filteredSpots = spots
              self.spots.append(contentsOf: spotsToAppend)
              self.filteredSpots.append(contentsOf: spotsToAppend)
              
              self.tableView.reloadData()
            }
          } else {
            Spot.searchSpotsWithName(startedWith: lowerCasedSearchText) { spotsToAppend in
              self.spots = spots
              self.filteredSpots = spots
              self.spots.append(contentsOf: spotsToAppend)
              self.filteredSpots.append(contentsOf: spotsToAppend)
              
              self.tableView.reloadData()
            }
          }
        }
      } else {
        // filter items from already downloaded from db
        filteredSpots = spots.filter { $0.name.hasPrefix(searchText) }
        
        if String.isLowercase(string: searchText) {
          filteredSpots.append(contentsOf: spots.filter { $0.name.hasPrefix(upperCasedSearchText) })
        } else {
          filteredSpots.append(contentsOf: spots.filter { $0.name.hasPrefix(lowerCasedSearchText) })
        }
        
        self.tableView.reloadData()
      }
      
    default: break
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "fromSearchToSpotInfo":
      let spotInfoController = (segue.destination as! SpotInfoController)
      spotInfoController.spotInfo = spotDetailsForSendingToSpotInfoController
      
    case "fromSearchToUserProfile":
      let userProfileController = segue.destination as! UserProfileController
      userProfileController.cameFromSpotDetails = true
      
    case "fromSearchToRiderProfile":
      let newRidersProfileController = segue.destination as! RidersProfileController
      newRidersProfileController.ridersInfo = riderItemForSending
      newRidersProfileController.title = riderItemForSending.login
      
    default: break
    }
  }
}

extension SearchController: UISearchBarDelegate {
  // MARK: - UISearchBar Delegate
  func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    searchBar.text = ""
    
    clearTableData()
    
    self.selectedScope = searchBar.scopeButtonTitles![selectedScope]
  }
  
  fileprivate func clearTableData() {
    riders.removeAll()
    filteredRiders.removeAll()
    spots.removeAll()
    filteredSpots.removeAll()
    
    tableView.reloadData()
  }
}

extension SearchController: UISearchResultsUpdating {
  // MARK: - UISearchResultsUpdating Delegate
  func updateSearchResults(for searchController: UISearchController) {
    if searchController.isActive && searchController.searchBar.text != "" {
      filterContentForSearchText(searchController.searchBar.text!)
    }
    
    if searchController.searchBar.text == "" {
      clearTableData()
    }
  }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension SearchController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
  func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    let str = NSLocalizedString("Nothing to show", comment: "")
    let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
    return NSAttributedString(string: str, attributes: attrs)
  }
  
  func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    let str = NSLocalizedString("Start entering something", comment: "")
    let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
    return NSAttributedString(string: str, attributes: attrs)
  }
}
