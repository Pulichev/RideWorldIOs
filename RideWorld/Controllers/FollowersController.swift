//
//  FollowersControllers.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 14.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class FollowersController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  @IBOutlet var tableView: UITableView! {
    didSet {
      tableView.delegate = self
      tableView.dataSource = self
      tableView.emptyDataSetSource = self
      tableView.emptyDataSetDelegate = self
      tableView.tableFooterView = UIView()
    }
  }
  
  var userId: String!
  var followersOrFollowingList: Bool! // if true - followers else - following
  fileprivate var followList = [UserItem]()
  
  override func viewDidLoad() {
    loadFollowList()
  }
  
  private func loadFollowList() {
    if followersOrFollowingList == true { // followers ref
      UserModel.getFollowersList(for: userId) { followersList in
        self.followList = followersList
        
        self.haveWeFinishedLoading = true
        self.tableView.reloadData()
      }
    } else { // following ref
      UserModel.getFollowingsList(for: userId) { followingsList in
        self.followList = followingsList
        
        self.haveWeFinishedLoading = true
        self.tableView.reloadData()
      }
    }
  }
  
  // MARK: - TableView delegate
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return followList.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "FollowersCell", for: indexPath) as! FollowersCell
    let row = indexPath.row
    
    cell.follower = followList[row]
    
    // adding tap event -> perform segue to profile
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sendRowToGoToProfile(_:)))
    cell.userImage.tag = row
    cell.userImage.isUserInteractionEnabled = true
    cell.userImage.addGestureRecognizer(tapGestureRecognizer)
    
    return cell
  }
  
  // here is redirecting to user profile by click on row.
  // So we have 2 redirects. By image and by row
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    let row = indexPath.row
    
    goToProfile(row: row)
  }
  
  // Idk how to make next 2 func to be 1
  @objc func sendRowToGoToProfile(_ sender: UIGestureRecognizer) {
    goToProfile(row: (sender.view?.tag)!)
  }
  
  func goToProfile(row: Int) {
    if followList[row].uid == UserModel.getCurrentUserId() {
      performSegue(withIdentifier: "openUserProfileFromFollowList", sender: self)
    } else {
      ridersInfoForSending = followList[row]
      performSegue(withIdentifier: "openRidersProfileFromFollowList", sender: self)
    }
  }
  
  var ridersInfoForSending: UserItem!
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "openRidersProfileFromFollowList":
      let newRidersProfileController = segue.destination as! RidersProfileController
      newRidersProfileController.ridersInfo = ridersInfoForSending
      newRidersProfileController.title = ridersInfoForSending.login
      newRidersProfileController.delegateFollowTaps = self
      
    case "openUserProfileFromFollowList":
      let userProfileController = segue.destination as! UserProfileController
      userProfileController.cameFromSpotDetails = true
      
    default: break
    }
  }
  
  var haveWeFinishedLoading = false // bool value have we loaded followers list or not. Mainly for DZNEmptyDataSet
}

extension FollowersController: FollowTappedFromProfile {
  func followTapped(on userId: String) {
    // update follow button
    let index = followList.index(where: { $0.uid == userId })
    
    let indexPath = [IndexPath(row: index!, section: 0)]
    
    // update cell
    tableView.beginUpdates()
    tableView.reloadRows(at: indexPath, with: .none)
    tableView.endUpdates()
  }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension FollowersController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
  func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    if haveWeFinishedLoading {
      let str = ":("
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
      return NSAttributedString(string: str, attributes: attrs)
    } else {
      let str = NSLocalizedString("Wait, please", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
      return NSAttributedString(string: str, attributes: attrs)
    }
  }
  
  func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    if haveWeFinishedLoading {
      let str = NSLocalizedString("Nothing to show.", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
      return NSAttributedString(string: str, attributes: attrs)
    } else {
      let str = NSLocalizedString("Loading list..", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
      return NSAttributedString(string: str, attributes: attrs)
    }
  }
}
