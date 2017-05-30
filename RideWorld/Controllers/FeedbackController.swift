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
   private let userId: String = User.getCurrentUserId()
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
         addPopoverWithLikes()
         perform(#selector(setIsViewedPropToTrue), with: nil, afterDelay: 3.0)
      }
   }
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      initializeCurrentUserItem()
      loadFeedbackItems()
   }
   
   private func initializeCurrentUserItem() {
      User.getItemById(for: userId) { user in
         self.userItem = user
      }
   }
   
   private func loadFeedbackItems() {
      FeedbackItem.getArray() { fbItems in
         self.feedbackItems = fbItems
         self.tableView.reloadData()
      }
   }
   
   @IBAction func reloadData(_ sender: Any) {
      FeedbackItem.getArray() { fbItems in
         self.feedbackItems = fbItems
         self.tableView.reloadData()
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
      cell.userId = followItem.userId
      cell.desc.text = "started following you."
      cell.dateTime.text = DateTimeParser.getDateTime(from: followItem.dateTime)
      
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
         cell.userId = commentFBItem.userId
         cell.postId = commentFBItem.postId
         cell.postItem = commentFBItem.postItem!
         if commentFBItem.postAddedByUser == User.getCurrentUserId() {
            cell.desc.text = "commented your photo: " + commentFBItem.text
         } else { // for @userId not author
            cell.desc.text = "mentioned you in comment."
         }
         cell.dateTime.text = DateTimeParser.getDateTime(from: commentFBItem.dateTime)
      }
      
      if fbItem is LikeFBItem {
         let likeFBItem = fbItem as! LikeFBItem
         cell.delegateUserTaps = self
         cell.delegatePostTaps = self
         cell.userId = likeFBItem.userId
         cell.postId = likeFBItem.postId
         cell.postItem = likeFBItem.postItem!
         cell.desc.text = "liked your photo."
         cell.dateTime.text = DateTimeParser.getDateTime(from: likeFBItem.dateTime)
      }
      
      return cell
   }
   
   // on open - set isViewed to true after 3 seconds delay
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      //      if feedbackItems.count != 0 {
      //         addPopoverWithLikes()
      //         perform(#selector(setIsViewedPropToTrue), with: nil, afterDelay: 3.0)
      //      }
   }
   
   private func addPopoverWithLikes() {
      var countUnViewedFBItems = 0
      
      if feedbackItems.count != 0 {
         for fbItem in feedbackItems {
            if !fbItem.isViewed {
               countUnViewedFBItems += 1
            }
         }
      }
      
      if countUnViewedFBItems != 0 {
         self.tabBarController?.tabBar.items![2].badgeValue = String(countUnViewedFBItems)
      }
   }
   
   // this function will perform after 3 seconds
   func setIsViewedPropToTrue() {
      for fbItem in feedbackItems {
         if !fbItem.isViewed {
            User.setFeedbackIsViewedToTrue(withKey: fbItem.key)
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
         
      case "goToPostInfoFromFeedback":
         let newPostInfoController = segue.destination as! PostInfoViewController
         newPostInfoController.postInfo = postInfoForSending
         newPostInfoController.user = ridersInfoForSending
         newPostInfoController.isCurrentUserProfile = true
         
      default: break
      }
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension FeedbackController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
   func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = "Welcome"
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = "Nothing to show."
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
      if haveWeFinishedLoading {
         return Image.resize(UIImage(named: "no_photo.png")!,
                             targetSize: CGSize(width: 300.0, height: 300.0))
      } else {
         return Image.resize(UIImage(named: "PleaseWaitTxt.gif")!,
                             targetSize: CGSize(width: 300.0, height: 300.0))
      }
   }
}

// to send userItem from cell to perform segue
extension FeedbackController: TappedUserDelegate {
   func userInfoTapped(_ user: UserItem?) {
      if user != nil {
         ridersInfoForSending = user
         performSegue(withIdentifier: "openRidersProfileFromFeedbackList", sender: self)
      } else {
         showAlertThatUserLoginNotFounded()
      }
   }
   
   private func showAlertThatUserLoginNotFounded() {
      let alert = UIAlertController(title: "Error!",
                                    message: "No user has been founded!",
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
