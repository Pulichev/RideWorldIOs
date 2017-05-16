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
   
   @IBOutlet weak var tableView: UITableView! {
      didSet {
         tableView.delegate = self
         tableView.dataSource = self
         tableView.rowHeight = UITableViewAutomaticDimension
         tableView.estimatedRowHeight = 170
         tableView.emptyDataSetSource = self
         tableView.emptyDataSetDelegate = self
         tableView.tableFooterView = UIView() // deleting empty rows
      }
   }
   var feedbackItems = [FeedbackItem]()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      loadFeedbackItems()
   }
   
   // example of bad code. need review here
   private func loadFeedbackItems() {
      FeedbackItem.getArray(
         completion: { fbItems in
            self.feedbackItems = fbItems
            self.tableView.reloadData()
      })
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
      cell.userId = followItem.userId
      cell.desc.text = "started following you."
      cell.dateTime.text = DateTimeParser.getDateTime(from: followItem.dateTime)
      
      return cell
   }
   
   private func configureCommentAndLikeFBCell(_ indexPath: IndexPath) -> CommentAndLikeFBCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "CommentAndLikeFBCell", for: indexPath) as! CommentAndLikeFBCell
      
      let row = indexPath.row
      let fbItem = feedbackItems[row]
      
      if fbItem is CommentFBItem {
         let commentFBItem = fbItem as! CommentFBItem
         cell.userId = commentFBItem.userId
         cell.postId = commentFBItem.postId
         cell.desc.text = "commented your photo: " + commentFBItem.text
         cell.dateTime.text = DateTimeParser.getDateTime(from: commentFBItem.dateTime)
      }
      
      if fbItem is LikeFBItem {
         let likeFBItem = fbItem as! LikeFBItem
         cell.userId = likeFBItem.userId
         cell.postId = likeFBItem.postId
         cell.desc.text = "liked your photo."
         cell.dateTime.text = DateTimeParser.getDateTime(from: likeFBItem.dateTime)
      }
      
      return cell
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
         return Image.resize(UIImage(named: "no_photo.png")!, targetSize: CGSize(width: 300.0, height: 300.0))
      } else {
         return Image.resize(UIImage(named: "PleaseWaitTxt.gif")!, targetSize: CGSize(width: 300.0, height: 300.0))
      }
   }
}
