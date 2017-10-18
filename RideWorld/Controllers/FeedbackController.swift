//
//  FeedbackController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher

class FeedbackController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
  private let userId: String = UserModel.getCurrentUserId()
  fileprivate var userItem: UserItem? // current user user item
  
  @IBOutlet weak var tableView: UITableView! {
    didSet {
      tableView.delegate = self
      tableView.dataSource = self
      tableView.estimatedRowHeight = 117
      tableView.rowHeight = UITableViewAutomaticDimension
      tableView.emptyDataSetSource = self
      tableView.emptyDataSetDelegate = self
      tableView.tableFooterView = UIView() // deleting empty rows
    }
  }
  
  var feedbackItems = [FeedbackItem]() {
    didSet {
      self.tableView.reloadData()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    initializeCurrentUserItem()
    
    if let tbc = self.tabBarController as? MainTabBarController {
      feedbackItems = tbc.feedbackItems
      tbc.delegateFBItemsChanges = self
      haveWeFinishedLoading = tbc.haveWeFinishedLoading
      tableView.reloadData()
    }
  }
  
  private func initializeCurrentUserItem() {
    UserModel.getItemById(for: userId) { user in
      self.userItem = user
    }
  }
  
  var haveWeFinishedLoading: Bool = false // bool value have we loaded feed or not. Mainly for DZNEmptyDataSet
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = indexPath.row
    var cell: UITableViewCell!
    let type = feedbackItems[row].type
    if type == 1 {
      cell = configureFollowerFBCell(indexPath)
    }
    
    if type == 2 || type == 3 {
      cell = configureCommentAndLikeFBCell(indexPath)
    }
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return feedbackItems.count
  }
  
  private func configureFollowerFBCell(_ indexPath: IndexPath) -> FollowerFBCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "FollowerFBCell", for: indexPath) as! FollowerFBCell
    
    let row = indexPath.row
    let followItem = feedbackItems[row] as! FollowerFBItem
    cell.delegate = self // for user info taps to perform segue
    cell.initialize(with: followItem)
    
    return cell
  }
  
  var ridersInfoForSending: UserItem?
  var postInfoForSending: PostItem?
  
  private func configureCommentAndLikeFBCell(_ indexPath: IndexPath) -> CommentAndLikeFBCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CommentAndLikeFBCell", for: indexPath) as! CommentAndLikeFBCell
    
    let row = indexPath.row
    let fbItem = feedbackItems[row]
    
    if fbItem is CommentFBItem {
      let commentFBItem = fbItem as! CommentFBItem
      cell.delegateUserTaps = self
      cell.delegatePostTaps = self
      cell.initializeForComment(with: commentFBItem)
    }
    
    if fbItem is LikeFBItem {
      let likeFBItem = fbItem as! LikeFBItem
      cell.delegateUserTaps = self
      cell.delegatePostTaps = self
      cell.initializeForLike(with: likeFBItem)
    }
    
    return cell
  }
  
  // MARK: - Badge delegate and processing
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    perform(#selector(setIsViewedPropToTrue), with: nil, afterDelay: 3.0)
  }
  
  // this function will perform after 3 seconds
  @objc func setIsViewedPropToTrue() {
    for fbItem in feedbackItems {
      if !fbItem.isViewed {
        UserModel.setFeedbackIsViewedToTrue(withKey: fbItem.key)
      }
    }
    
    self.tabBarController?.tabBar.items![2].badgeValue = nil
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "openRidersProfileFromFeedbackList":
      let newRidersProfileController = segue.destination as! RidersProfileController
      newRidersProfileController.ridersInfo = ridersInfoForSending
      newRidersProfileController.title = ridersInfoForSending?.login
      newRidersProfileController.delegateFollowTaps = self
      
    case "goToPostInfoFromFeedback":
      let newPostInfoController = segue.destination as! PostInfoController
      newPostInfoController.postInfo = postInfoForSending
      newPostInfoController.isCurrentUserProfile = true
      newPostInfoController.cameFromFeedback = true
      
    case "openUserProfileFromFB":
      let userProfileController = segue.destination as! UserProfileController
      userProfileController.cameFromSpotDetails = true // maybe useless property
      
    default: break
    }
  }
}

extension FeedbackController: FeedbackItemsDelegate {
  func lastUpdate(_ items: [FeedbackItem]) {
    feedbackItems = items
    haveWeFinishedLoading = true
    tableView.reloadData()
  }
}

extension FeedbackController: FollowTappedFromProfile {
  func followTapped(on userId: String) {
    // update follow button
    for fbItem in feedbackItems {
      if fbItem.type == 1 { // if follower fb type
        let followItem = fbItem as! FollowerFBItem
        if followItem.userId == userId {
          let index = feedbackItems.index(where: { $0.key == followItem.key })
          
          let indexPath = [IndexPath(row: index!, section: 0)]
          
          // update cell
          tableView.beginUpdates()
          tableView.reloadRows(at: indexPath, with: .none)
          tableView.endUpdates()
        }
      }
    }
  }
}

// to send userItem from cell to perform segue
extension FeedbackController: TappedUserDelegate {
  func userInfoTapped(_ user: UserItem?) {
    if user != nil {
      if user!.uid != UserModel.getCurrentUserId() {
        ridersInfoForSending = user
        performSegue(withIdentifier: "openRidersProfileFromFeedbackList", sender: self)
      } else {
        performSegue(withIdentifier: "openUserProfileFromFB", sender: self)
      }
    } else {
      showAlertThatUserLoginNotFounded()
    }
  }
  
  private func showAlertThatUserLoginNotFounded() {
    let alert = UIAlertController(title: NSLocalizedString("Error!", comment: ""),
                                  message: NSLocalizedString("No user has been founded!", comment: ""),
                                  preferredStyle: .alert)
    
    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
    present(alert, animated: true, completion: nil)
  }
}

// to send postItem from cell to performSegue
extension FeedbackController: TappedPostDelegate {
  func postInfoTapped(_ tappedPost: PostItem) {
    if userItem != nil {
      self.ridersInfoForSending = userItem
      self.postInfoForSending = tappedPost
      self.performSegue(withIdentifier: "goToPostInfoFromFeedback", sender: self)
    }
  }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension FeedbackController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
  func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    if haveWeFinishedLoading {
      let str = NSLocalizedString("Welcome", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
      return NSAttributedString(string: str, attributes: attrs)
    } else {
      let str = NSLocalizedString("Loading...", comment: "")
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
      let str = ""
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
      return NSAttributedString(string: str, attributes: attrs)
    }
  }
  
  func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
    if haveWeFinishedLoading {
      return MyImage.resize(sourceImage: UIImage(named: "no_photo.png")!,
                            toWidth: CGFloat(300)).image
    } else {
      return nil
    }
  }
}
