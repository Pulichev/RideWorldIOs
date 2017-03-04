//
//  spotPostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
//  Using this class to cache text info from SpotPostCells

import Foundation

class SpotPostItemCellCache {
    var backendless = Backendless.sharedInstance()

    var post: SpotPostItem
    var userNickName = UILabel()
    var postDate = UILabel()
    var postDescription = UITextView()
    var isPhoto = Bool()
    var isLikedPhoto = UIImageView()
    var postIsLiked = Bool()
    var likesCount = Int()
    var userInfo = Users()
    
    init(spotPost: SpotPostItem) {
        self.post = spotPost
        //self.userInfo = post.user //getting userinfo
        self.userNickName.text = self.userInfo.name
        let sourceDate = post.createdDate
        //formatting date to yyyy-mm-dd
        let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
        self.postDate.text = finalDate
        self.postDescription.text = post.description
        self.isPhoto = post.isPhoto
        self.userLikedThisPost()
        self.countPostLikes()
    }

    func userLikedThisPost() {
        if (true) { //If user has liked this post already //TODOODODOASDOAODAOSDOASDOASODO
            postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
        } else {
            postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
        }
    }

    func countPostLikes() {
        self.likesCount = 13
    }

    func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
        if (!postIsLiked) { //If user has liked this post already
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
