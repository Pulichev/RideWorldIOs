//
//  CommentariesContoller.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import ActiveLabel

class CommentariesController: UIViewController, UITableViewDataSource,
UITableViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    var postId: String!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newCommentTextField: UITextField!
    
    var comments = [CommentItem]()
    var postDescription: String? // For adding desc as comment
    var userId: String? // For adding desc as comment
    var postDate: String! // For adding desc as comment
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadComments()
        
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(CommentariesController.keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentariesController.keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.newCommentTextField.delegate = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 150
        self.tableView.tableFooterView = UIView() // deleting empty rows
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadComments() {
        self.addPostDescAsComment()
        
        CommentsModel.loadCommentsForPost(
            postId: self.postId,
            completion: { loadedComments in
                self.comments.append(contentsOf: loadedComments)
                
                self.tableView.reloadData()
        })
    }
    
    func addPostDescAsComment() {
        let descAsComment = CommentItem(commentId: "", userId: self.userId!, postId: self.postId, commentary: self.postDescription!, datetime: self.postDate)
        self.comments.append(descAsComment)
    }
    
    @IBAction func sendComment(_ sender: Any) {
        CommentsModel.addNewComment(
            postId: self.postId, text: self.newCommentTextField.text,
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
        return self.comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsTableCell", for: indexPath) as! CommentCell
        let row = indexPath.row
        
        cell.comment = self.comments[row]
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
    
    // MARK: - DZNEmptyDataSet for empty data tables
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
    
    // from comment author
    func goToProfile(_ sender: UIGestureRecognizer) {
        let userId = self.comments[(sender.view?.tag)!].userId
        
        if userId == UserModel.getCurrentUserId() {
            self.performSegue(withIdentifier: "openUserProfileFromCommentsList", sender: self)
        } else {
            UserModel.getUserItemById(
                userId: userId,
                completion: { fetchedUserItem in
                    self.ridersInfoForSending = fetchedUserItem
                    self.performSegue(withIdentifier: "openRidersProfileFromCommentsList", sender: self)
            })
        }
    }
    
    // from @username
    private func goToUserProfile(tappedUserLogin: String) {
        UserModel.getUserItemByLogin(
            userLogin: tappedUserLogin,
            completion: { fetchedUserItem in
                if let userItem = fetchedUserItem { // have we founded?
                    if userItem.uid == UserModel.getCurrentUserId() {
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
        
        self.present(alert, animated: true, completion: nil)
    }
    
    var ridersInfoForSending: UserItem!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openRidersProfileFromCommentsList" {
            let newRidersProfileController = segue.destination as! RidersProfileController
            newRidersProfileController.ridersInfo = ridersInfoForSending
            newRidersProfileController.title = ridersInfoForSending.login
        }
        
        if segue.identifier == "openUserProfileFromCommentsList" {
            let userProfileController = segue.destination as! UserProfileController
            userProfileController.cameFromSpotDetails = true
        }
    }
}

extension CommentariesController: UITextFieldDelegate {
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            let swipeSize = keyboardHeight - 49
            self.view.frame.origin.y -= swipeSize
            let tableViewBound = self.tableView.frame
            let tableViewHeight = self.tableView.bounds.height
            self.tableView.frame = CGRect(x: tableViewBound.minX, y: tableViewBound.minY + swipeSize,
                                          width: tableViewBound.maxX, height: tableViewHeight - swipeSize)
            print(self.view.frame.origin.y)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            let swipeSize = keyboardHeight - 49
            self.view.frame.origin.y += swipeSize
            let tableViewBound = self.tableView.frame
            let tableViewHeight = self.tableView.bounds.height
            self.tableView.frame = CGRect(x: tableViewBound.minX, y: tableViewBound.minY - swipeSize,
                                          width: tableViewBound.maxX, height: tableViewHeight + swipeSize)
            print(self.view.frame.origin.y)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
