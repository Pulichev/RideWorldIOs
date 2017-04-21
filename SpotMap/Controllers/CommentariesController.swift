//
//  CommentariesContoller.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel

class CommentariesController: UIViewController, UITableViewDataSource,
UITableViewDelegate {
   var postId: String!
   
   @IBOutlet weak var tableView: UITableView! {
      didSet {
         tableView.delegate = self
         tableView.dataSource = self
         tableView.emptyDataSetSource = self
         tableView.emptyDataSetDelegate = self
         tableView.rowHeight = UITableViewAutomaticDimension
         tableView.estimatedRowHeight = 150
         tableView.tableFooterView = UIView() // deleting empty rows
      }
   }
   @IBOutlet weak var newCommentTextField: UITextField! {
      didSet {
         newCommentTextField.delegate = self
      }
   }
   
   var comments = [CommentItem]()
   var postDescription: String? //
   var userId: String?          // For adding desc as comment
   var postDate: String!        //
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      loadComments()
      
      //For scrolling the view if keyboard on
      NotificationCenter.default.addObserver(self, selector: #selector(CommentariesController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(CommentariesController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
   }
   
   func loadComments() {
      addPostDescAsComment()
      
      CommentsModel.loadComments(
         for: postId,
         completion: { loadedComments in
            self.comments.append(contentsOf: loadedComments)
            
            self.tableView.reloadData()
      })
   }
   
   func addPostDescAsComment() {
      let descAsComment = CommentItem("", userId!, postId, postDescription!, postDate)
      comments.append(descAsComment)
   }
   
   @IBAction func sendComment(_ sender: UIButton) {
      CommentsModel.addNewComment(
         for: postId, withText: newCommentTextField.text,
         completion: { newComment in
            self.newCommentTextField.text = ""
            self.view.endEditing(true)
            
            self.comments.append(newComment)
            self.tableView.reloadData()
      })
   }
   
   func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return comments.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsTableCell", for: indexPath) as! CommentCell
      let row = indexPath.row
      
      cell.comment = comments[row]
      // adding tap event -> perform segue to profile
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToProfile(_:)))
      cell.userPhoto.tag = row
      cell.userPhoto.isUserInteractionEnabled = true
      cell.userPhoto.addGestureRecognizer(tapGestureRecognizer)
      cell.commentText.handleMentionTap { mention in // mention is @userLogin
         self.goToUserProfile(tappedUserLogin: mention)
      }
      
      return cell
   }
   
   // from comment author
   func goToProfile(_ sender: UIGestureRecognizer) {
      let userId = comments[(sender.view?.tag)!].userId
      
      if userId == User.getCurrentUserId() {
         performSegue(withIdentifier: "openUserProfileFromCommentsList", sender: self)
      } else {
         User.getItemById(
            for: userId,
            completion: { fetchedUserItem in
               self.ridersInfoForSending = fetchedUserItem
               self.performSegue(withIdentifier: "openRidersProfileFromCommentsList", sender: self)
         })
      }
   }
   
   // from @username
   private func goToUserProfile(tappedUserLogin: String) {
      User.getItemByLogin(
         for: tappedUserLogin,
         completion: { fetchedUserItem in
            if let userItem = fetchedUserItem { // have we founded?
               if userItem.uid == User.getCurrentUserId() {
                  self.performSegue(withIdentifier: "openUserProfileFromCommentsList", sender: self)
               } else {
                  self.ridersInfoForSending = userItem
                  self.performSegue(withIdentifier: "openRidersProfileFromCommentsList", sender: self)
               }
            } else { // if no user founded for tapped nickname
               self.showAlertThatUserLoginNotFounded(tappedUserLogin: tappedUserLogin)
            }
      })
   }
   
   private func showAlertThatUserLoginNotFounded(tappedUserLogin: String) {
      let alert = UIAlertController(title: "Error!",
                                    message: "No user founded with nickname \(tappedUserLogin)",
         preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   var ridersInfoForSending: UserItem!
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "openRidersProfileFromCommentsList":
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = ridersInfoForSending
         newRidersProfileController.title = ridersInfoForSending.login
         
      case "openUserProfileFromCommentsList":
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
         
      default: break
      }
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension CommentariesController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
   func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      let str = ":("
      let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
      return NSAttributedString(string: str, attributes: attrs)
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      let str = "Nothing to show"
      let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
      return NSAttributedString(string: str, attributes: attrs)
   }
   
}

// MARK: - Scroll view on keyboard show/hide
extension CommentariesController: UITextFieldDelegate {
   func keyboardWillShow(notification: NSNotification) {
      if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
         let keyboardHeight = keyboardSize.height
         let swipeSize = keyboardHeight - 49
         view.frame.origin.y -= swipeSize
         let tableViewBound = tableView.frame
         let tableViewHeight = tableView.bounds.height
         tableView.frame = CGRect(x: tableViewBound.minX, y: tableViewBound.minY + swipeSize,
                                       width: tableViewBound.maxX, height: tableViewHeight - swipeSize)
         print(view.frame.origin.y)
      }
   }
   
   func keyboardWillHide(notification: NSNotification) {
      if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
         let keyboardHeight = keyboardSize.height
         let swipeSize = keyboardHeight - 49
         view.frame.origin.y += swipeSize
         let tableViewBound = tableView.frame
         let tableViewHeight = tableView.bounds.height
         tableView.frame = CGRect(x: tableViewBound.minX, y: tableViewBound.minY - swipeSize,
                                       width: tableViewBound.maxX, height: tableViewHeight + swipeSize)
         print(view.frame.origin.y)
      }
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      view.endEditing(true)
   }
}
