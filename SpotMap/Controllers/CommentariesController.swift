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

class CommentariesController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    var postId: String!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newCommentTextField: UITextField!
    
    var comments = [CommentItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadComments()
        
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(CommentariesController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentariesController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.newCommentTextField.delegate = self
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 350
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadComments() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postId).child("comments")
        
        ref.queryOrdered(byChild: "key").observe(.value, with: { snapshot in
            var newItems: [CommentItem] = []
            
            for item in snapshot.children {
                let commentItem = CommentItem(snapshot: item as! FIRDataSnapshot)
                newItems.append(commentItem)
            }
            
            self.comments = newItems.sorted(by: { $0.commentId < $1.commentId })
            // TODO: need to insert description here
            self.tableView.reloadData()
        })
    }
    
    @IBAction func sendComment(_ sender: Any) {
        let refForNewComment = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postId).child("comments").childByAutoId()
        
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        let currentDateTime = String(describing: Date())
        let newComment = CommentItem(commentId: refForNewComment.key, userId: currentUserId!, postId: self.postId, commentary: newCommentTextField.text!, datetime: currentDateTime)
        
        refForNewComment.setValue(newComment.toAnyObject())
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
        
        return cell
    }
    
    func goToProfile(_ sender: UIGestureRecognizer) {
        let userId = self.comments[(sender.view?.tag)!].userId
        
        if userId == (FIRAuth.auth()?.currentUser?.uid)! {
            self.performSegue(withIdentifier: "openUserProfileFromCommentsList", sender: self)
        } else {
            let ref = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(userId)
            
            ref.observeSingleEvent(of: .value, with: { snapshot in
                let user = UserItem(snapshot: snapshot)
                self.ridersInfoForSending = user
                self.performSegue(withIdentifier: "openRidersProfileFromCommentsList", sender: self)
            })
        }
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

    // MARK: DZNEmptyDataSet for empty data tables
    
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
    
    // ENDMARK: DZNEmptyDataSet
    
    var keyBoardAlreadyShowed = false //using this to not let app to scroll view
    //if we tapped UITextField and then another UITextField
}

extension CommentariesController: UITextFieldDelegate {
    func keyboardWillShow(notification: NSNotification) {
        if !keyBoardAlreadyShowed {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                let keyboardHeight = keyboardSize.height
                self.view.frame.origin.y -= (keyboardHeight - 49)
                keyBoardAlreadyShowed = true
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            self.view.frame.origin.y += (keyboardHeight - 49)
            keyBoardAlreadyShowed = false
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
