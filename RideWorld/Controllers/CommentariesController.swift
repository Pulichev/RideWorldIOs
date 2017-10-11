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
import SVProgressHUD

class CommentariesController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   
   var post: PostItem!
   
   @IBOutlet weak var tableView: UITableView! {
      didSet {
         tableView.delegate = self
         tableView.dataSource = self
         tableView.estimatedRowHeight = 80
         tableView.rowHeight = UITableViewAutomaticDimension
         tableView.emptyDataSetSource = self
         tableView.emptyDataSetDelegate = self
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
   
   func loadComments() {
      self.addPostDescAsComment() { _ in
         Comment.loadList(
         for: self.post.key) { loadedComments in
            self.comments.append(contentsOf: loadedComments)
            
            self.tableView.reloadData()
         }
      }
   }
   
   func addPostDescAsComment(completion: @escaping (_ isAdded: Bool) -> Void) {
      let _ = CommentItem(userId!, post.key,
                          post.addedByUser, postDescription!,
                          postDate, "") { item in
                           if item != nil {
                              self.comments.append(item!)
                              self.tableView.reloadData()
                           }
                           completion(true)
      }
   }
   
   @IBOutlet weak var sendCommentButton: UIButtonX!
   
   @IBAction func sendComment(_ sender: UIButton) {
      if newCommentTextField.text != "" {
         sendCommentButton.isEnabled = false
         SVProgressHUD.show()
         
         Comment.add(for: post,
                     withText: newCommentTextField.text)
         { newComment in
            self.sendCommentButton.isEnabled = true
            SVProgressHUD.dismiss()
            
            self.newCommentTextField.text = ""
            self.view.endEditing(true)
            
            self.comments.append(newComment)
            // add to tableView
            self.tableView.beginUpdates()
            let lastIndex = IndexPath(row: self.comments.count - 1, section: 0)
            self.tableView.insertRows(at: [lastIndex], with: .none)
            self.tableView.endUpdates()
         }
      } else {
         showAlertWithError(text: NSLocalizedString("New comment can't be empty!", comment: ""))
      }
   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return comments.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsTableCell", for: indexPath) as! CommentCell
      let row = indexPath.row
      
      cell.delegateUserTaps = self
      
      cell.comment = comments[row]
      cell.userItem = cell.comment.userItem
      cell.commentTextInfo = cell.userItem.login + " " + cell.comment.commentary
      // adding tap event -> perform segue to profile
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToProfile(_:)))
      cell.userPhoto.tag = row
      cell.userPhoto.isUserInteractionEnabled = true
      cell.userPhoto.addGestureRecognizer(tapGestureRecognizer)
      
      //configure right buttons
      addFuncButtons(to: cell, at: row)
      
      return cell
   }
   
   private func addFuncButtons(to cell: CommentCell, at row: Int) {
      let currentUserId = UserModel.getCurrentUserId()
      
      if (cell.comment.userId == currentUserId // if its current user comment
         || userId! == currentUserId) // if current user is post author
         && cell.comment.key != "" { // cant delete desc
         cell.rightButtons = [
            MGSwipeButton(title: "", icon: UIImage(named:"deleteInComments"), backgroundColor: .red) {
               (sender: MGSwipeTableCell!) -> Bool in
               self.removeCell(cell, at: row)
               return true
            },
            MGSwipeButton(title: "", icon: UIImage(named:"replyInComments"), backgroundColor: .darkGray) {
               (sender: MGSwipeTableCell!) -> Bool in
               self.replyToUser(with: cell.userItem.login)
               return true
            }
         ]
      } else {
         // add only reply button
         cell.rightButtons = [
            MGSwipeButton(title: "", icon: UIImage(named:"replyInComments"), backgroundColor: .darkGray) {
               (sender: MGSwipeTableCell!) -> Bool in
               self.replyToUser(with: cell.userItem.login)
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
   @objc func goToProfile(_ sender: UIGestureRecognizer) {
      let userId = comments[(sender.view?.tag)!].userId
      
      if userId == UserModel.getCurrentUserId() {
         performSegue(withIdentifier: "openUserProfileFromCommentsList", sender: self)
      } else {
         self.ridersInfoForSending = comments[(sender.view?.tag)!].userItem
         self.performSegue(withIdentifier: "openRidersProfileFromCommentsList", sender: self)
      }
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
   
   private func showAlertWithError(text: String) {
      let alert = UIAlertController(title: "Woops!",
                                    message: text,
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   @IBOutlet weak var newCommentViewBotConstraint: NSLayoutConstraint!
}

extension CommentariesController: TappedUserDelegate {
   func userInfoTapped(_ user: UserItem?) {
      if user != nil {
         if user?.uid == UserModel.getCurrentUserId() {
            self.performSegue(withIdentifier: "openUserProfileFromCommentsList", sender: self)
         } else {
            ridersInfoForSending = user
            performSegue(withIdentifier: "openRidersProfileFromCommentsList", sender: self)
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

// MARK: - Scroll view on keyboard show/hide
extension CommentariesController: UITextFieldDelegate {
   @objc func keyboardWillShow(notification: NSNotification) {
      if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
         let keyboardHeight = keyboardSize.height
         UIView.animate(withDuration: 1.0, animations: {
            self.newCommentViewBotConstraint.constant = -keyboardHeight
            self.view.layoutIfNeeded()
         })
      }
   }
   
   @objc func keyboardWillHide(notification: NSNotification) {
      self.newCommentViewBotConstraint.constant = 0
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      view.endEditing(true)
   }
}

// MARK: - viewWillAppear/Dissappear
extension CommentariesController {
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      let mainTabBarController = tabBarController as? MainTabBarController
      mainTabBarController?.hideMapButton()
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      self.newCommentViewBotConstraint.constant = 0
      
      let mainTabBarController = tabBarController as? MainTabBarController
      mainTabBarController?.showMapButton()
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension CommentariesController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
   func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      let str = NSLocalizedString("Wait please", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
      return NSAttributedString(string: str, attributes: attrs)
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      let str = NSLocalizedString("Downloading data..", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
      return NSAttributedString(string: str, attributes: attrs)
   }
}
