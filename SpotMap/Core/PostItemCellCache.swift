//
//  PostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
//  Using this class to cache text info from SpotPostCells

import Foundation
import FirebaseDatabase
import FirebaseAuth
import ActiveLabel

class PostItemCellCache {
    var key: String!
    var post: PostItem!
    var userInfo: UserItem!
    var userNickName = String()
    var postDate = String()
    var postTime = String()
    var postDescription = String()
    var isPhoto = Bool()
    var isLikedPhoto = UIImageView()
    var postIsLiked = Bool()
    var likesCount = Int()
    var isCached = false
    
    init(spotPost: PostItem, stripController: PostsStripController) {
        self.key = spotPost.key
        self.post = spotPost
        initializeUser()
        let sourceDate = post.createdDate
        // formatting date to yyyy-mm-dd
        let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
        self.postDate = finalDate
        let finalTime = sourceDate[sourceDate.index(sourceDate.startIndex, offsetBy: 11)..<sourceDate.index(sourceDate.startIndex, offsetBy: 16)]
        self.postTime = finalTime
        self.postDescription = post.description
        self.isPhoto = post.isPhoto
        self.userLikedThisPost(stripController: stripController)
        self.countPostLikes(stripController: stripController)
    }
    
    func initializeUser() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(post.addedByUser)
        
        ref.observe(.value, with: { (snapshot) in
            self.userInfo = UserItem(snapshot: snapshot)
            self.userNickName = self.userInfo.login
        })
    }
    
    func userLikedThisPost(stripController: PostsStripController) {
        let userId = FIRAuth.auth()?.currentUser?.uid
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.post.key).child("likes").child(userId!)
        // catch if user liked this post
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? [String : Any] {
                self.postIsLiked = true
                self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            } else {
                self.postIsLiked = false
                self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            }
            stripController.tableView.reloadData()
        })
    }
    
    func countPostLikes(stripController: PostsStripController) {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.post.key).child("likes")
        //catch if user liked this post
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            self.likesCount = snapshot.children.allObjects.count
            stripController.tableView.reloadData()
        })
    }
    
    func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
        if (!self.postIsLiked) {
            self.postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            self.likesCount += 1
        } else {
            self.postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            self.likesCount -= 1
        }
    }
}
