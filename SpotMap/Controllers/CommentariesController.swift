//
//  CommentariesContoller.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 01.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import IGListKit
import FirebaseDatabase
import FirebaseAuth

class CommentariesController: UIViewController {
    var postId: String!
    
    var comments = [CommentItem]()
    
    let collectionView: IGListCollectionView = {
        let view = IGListCollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
        return view
    }()
    
    lazy var adapter: IGListAdapter = {
        return IGListAdapter(updater: IGListAdapterUpdater(), viewController: self, workingRangeSize: 0)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadComments()
        self.view.backgroundColor = UIColor.white
        
        //For scrolling the view if keyboard on
        NotificationCenter.default.addObserver(self, selector: #selector(CommentariesController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentariesController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.newCommentTextField.delegate = self
        
        view.addSubview(collectionView)
        view.addSubview(sendCommentButton)
        view.addSubview(newCommentTextField)
        adapter.collectionView = collectionView
        adapter.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let screenSize: CGRect = self.view.bounds
        collectionView.frame = CGRect(x: 0, y: 5, width: self.view.bounds.width, height: self.view.bounds.height - 55)
        sendCommentButton.frame = CGRect(x: screenSize.width * 0.7 + 5, y: screenSize.height - 50,
                                        width: screenSize.width * 0.3 - 10, height: 45)
        newCommentTextField.frame = CGRect(x: 5, y: screenSize.height - 50,
                                           width: screenSize.width * 0.7 - 10, height: 45)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    lazy var sendCommentButton: UIButton! = {
        let screenSize: CGRect = self.view.bounds
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addTarget(self, action: #selector(CommentariesController.sendComment), for: .touchDown)
        view.setTitle("Send", for: .normal)
        view.backgroundColor = UIColor.gray
        view.titleLabel?.textAlignment = .center
        return view
    }()
    
    lazy var newCommentTextField: UITextField! = {
        let screenSize: CGRect = self.view.bounds
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.borderStyle = .roundedRect
        view.textAlignment = .center
        
        return view
    }()
    
    func sendComment() {
        let refForNewComment = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postId).child("comments").childByAutoId()
        
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        let currentDateTime = String(describing: Date())
        let newComment = CommentItem(userId: currentUserId!, postId: self.postId, commentary: newCommentTextField.text!, datetime: currentDateTime)
        
        refForNewComment.setValue(newComment.toAnyObject())
    }
    
    var keyBoardAlreadyShowed = false //using this to not let app to scroll view
    //if we tapped UITextField and then another UITextField
}

// MARK: - IGListAdapterDataSource
extension CommentariesController: IGListAdapterDataSource {
    func loadComments() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postId).child("comments")
        
        ref.queryOrdered(byChild: "key").observe(.value, with: { snapshot in
            var newItems: [CommentItem] = []
            
            for item in snapshot.children {
                let commentItem = CommentItem(snapshot: item as! FIRDataSnapshot)
                newItems.append(commentItem)
            }
            
            self.comments = newItems
            self.adapter.reloadData(completion: nil)
        })
    }
    
    func objects(for listAdapter: IGListAdapter) -> [IGListDiffable] {
        var items = [IGListDiffable]()
        
        items = self.comments as [IGListDiffable]
        
        return items
    }
    
    func listAdapter(_ listAdapter: IGListAdapter, sectionControllerFor object: Any) -> IGListSectionController {
        return CommentariesSectionController()
    }
    
    func emptyView(for listAdapter: IGListAdapter) -> UIView? { return nil }
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
