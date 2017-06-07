//
//  CommentariesContoller.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel
import MGSwipeTableCell

class CommentariesController: UIViewController, UITableViewDataSource,
UITableViewDelegate {
   var post: PostItem!
   
   @IBOutlet weak var tableView: UITableView! {
      didSet {
         tableView.delegate = self
         tableView.dataSource = self
         tableView.emptyDataSetSource = self
         tableView.emptyDataSetDelegate = self
         tableView.estimatedRowHeight = 80
         tableView.rowHeight = UITableViewAutomaticDimension
         tableView.tableFooterView = UIView() // deleting empty rows
      }
   }
   @IBOutlet weak var newCommentTextField: UITextField! {
      didSet {
         newCommentTextField.delegate = self
         newCommentTextField.keyboardType = .twitter
      }
   }
   
   @IBOutlet weak var newCommentView: UIView!
   
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
      
      Comment.loadList(
      for: post.key) { loadedComments in
         self.comments.append(contentsOf: loadedComments)
         
         self.tableView.reloadData()
      }
   }
   
   func addPostDescAsComment() {
      let descAsComment = CommentItem(userId!, post.key,
                                      post.addedByUser, postDescription!,
                                      postDate, "")
      comments.append(descAsComment)
   }
   
   @IBAction func sendComment(_ sender: UIButton) {
      Comment.add(for: post,
                  withText: newCommentTextField.text)
      { newComment in
         self.newCommentTextField.text = ""
         self.view.endEditing(true)
         
         self.comments.append(newComment)
         // add to tableView
         self.tableView.beginUpdates()
         let lastIndex = IndexPath(row: self.comments.count - 1, section: 0)
         self.tableView.insertRows(at: [lastIndex], with: .none)
         self.tableView.endUpdates()
      }
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
      
      cell.userNickName.addTarget(self, action: #selector(goToUserProfileFromNickNameButton), for: .touchUpInside)
      
      //configure right buttons
      addFuncButtons(to: cell, at: row)
      
      return cell
   }
   
   private func addFuncButtons(to cell: CommentCell, at row: Int) {
      let currentUserId = User.getCurrentUserId()
      
      if (cell.comment.userId == currentUserId // if its current user comment
         || userId! == currentUserId) // if current user is post author
         && cell.comment.key != "" { // cant delete desc
         cell.rightButtons = [
            MGSwipeButton(title: "", icon: UIImage(named:"delete.png"), backgroundColor: .red) {
               (sender: MGSwipeTableCell!) -> Bool in
               self.removeCell(cell, at: row)
               return true
            },
            MGSwipeButton(title: "", icon: UIImage(named:"reply.png"), backgroundColor: .darkGray) {
               (sender: MGSwipeTableCell!) -> Bool in
               self.replyToUser(with: cell.userNickName.currentTitle!)
               return true
            }
         ]
      } else {
         // add only reply button
         cell.rightButtons = [
            MGSwipeButton(title: "", icon: UIImage(named:"reply.png"), backgroundColor: .darkGray) {
               (sender: MGSwipeTableCell!) -> Bool in
               self.replyToUser(with: cell.userNickName.currentTitle!)
               return true
            }
         ]
      }
      
      cell.rightSwipeSettings.transition = .rotate3D
   }
   
   private func removeCell(_ cell: CommentCell, at row: Int) {
      removeCellFromTable(cell, at: row)
      removeCellFromDataBase(cell)
   }
   
   private func removeCellFromTable(_ cell: CommentCell, at row: Int) {
      comments.remove(at: row)
      tableView.reloadData()
   }
   
   private func removeCellFromDataBase(_ cell: CommentCell) {
      Comment.remove(cell.comment, from: post)
   }
   
   private func replyToUser(with login: String) {
      newCommentTextField.text = newCommentTextField.text?.appending(" @" + login)
   }
   
   //MARK: - segues actions part
   // from comment author photo
   func goToProfile(_ sender: UIGestureRecognizer) {
      let userId = comments[(sender.view?.tag)!].userId
      
      if userId == User.getCurrentUserId() {
         performSegue(withIdentifier: "openUserProfileFromCommentsList", sender: self)
      } else {
         User.getItemById(for: userId) { fetchedUserItem in
            self.ridersInfoForSending = fetchedUserItem
            self.performSegue(withIdentifier: "openRidersProfileFromCommentsList", sender: self)
         }
      }
   }
   
   // nickname button tapped
   func goToUserProfileFromNickNameButton(sender: UIButton!) {
      goToUserProfile(tappedUserLogin: sender.currentTitle!)
   }
   
   // from @username
   private func goToUserProfile(tappedUserLogin: String) {
      User.getItemByLogin(
      for: tappedUserLogin) { fetchedUserItem in
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
      }
   }
   
   private func showAlertThatUserLoginNotFounded(tappedUserLogin: String) {
      let alert = UIAlertController(title: "Error!",
                                    message: "No user has been founded founded with nickname \(tappedUserLogin)",
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
   
   @IBOutlet weak var newCommentViewBotConstraint: NSLayoutConstraint!
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      self.newCommentViewBotConstraint.constant = 0
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
//         let tabBarHeight = tabBarController?.tabBar.frame.size.height
//         let navBarHeight = navigationController?.navigationBar.frame.size.height
         UIView.animate(withDuration: 1.0, animations: {
            self.newCommentViewBotConstraint.constant = -keyboardHeight + 43//tabBarHeight!
            self.view.layoutIfNeeded()
         })
      }
   }
   
   func keyboardWillHide(notification: NSNotification) {
      self.newCommentViewBotConstraint.constant = 0
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      view.endEditing(true)
   }
}
