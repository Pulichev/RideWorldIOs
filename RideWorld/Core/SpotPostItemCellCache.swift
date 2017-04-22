//
//  spotPostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
//  Using this class to cache text info from SpotPostCells

import Foundation
import FirebaseDatabase
import FirebaseAuth

class SpotPostItemCellCache {
    var post: SpotPostItem!
    var userInfo: UserItem!
    var userNickName = UILabel()
    var postDate = UILabel()
    var postDescription = UITextView()
    var isPhoto = Bool()
    var isLikedPhoto = UIImageView()
    var postIsLiked = Bool()
    var likesCount = Int()
    var isCached = false
    
    init(spotPost: SpotPostItem) {
        self.post = spotPost
        initializeUser()
        let sourceDate = post.createdDate
        // formatting date to yyyy-mm-dd
        let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
        self.postDate.text = finalDate
        self.postDescription.text = post.description
        self.isPhoto = post.isPhoto
        self.userLikedThisPost()
        self.countPostLikes()
    }
    
    func initializeUser() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/users/").child(post.addedByUser)
        
        ref.observe(.value, with: { (snapshot) in
            self.userInfo = UserItem(snapshot: snapshot)
            self.userNickName.text = self.userInfo.login
        })
    }
    
    func userLikedThisPost() {
        let userId = FIRAuth.auth()?.currentUser?.uid
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.post.key).child("likes").child(userId!)
        // catch if user liked this post
        likeRef.observe(.value, with: { snapshot in
            if let value = snapshot.value as? [String : Any] {
                self.postIsLiked = true
                self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            } else {
                self.postIsLiked = false
                self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            }
        })
    }
    
    func countPostLikes() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.post.key).child("likes")
        //catch if user liked this post
        likeRef.observe(.value, with: { snapshot in
            self.likesCount = snapshot.children.allObjects.count
        })
    }
    
    func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
        if (!postIsLiked) {
            postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            likesCount += 1
        } else {
            postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            likesCount -= 1
        }
    }
}