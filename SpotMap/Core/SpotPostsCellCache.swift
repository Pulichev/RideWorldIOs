//
//  spotPostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
//  Using this class to cache text info from SpotPostCells

import Foundation

class SpotPostsCellCache {
    var backendless = Backendless.sharedInstance()

    var post = SpotPost()
    var userNickName = UILabel()
    var postDate = UILabel()
    var postDescription = UITextView()
    var isPhoto = Bool()
    var isLikedPhoto = UIImageView()
    var postIsLiked = Bool()
    var likesCount = Int()
    var userInfo = Users()
    
    init(spotPost: SpotPost) {
        self.post = spotPost
        self.userInfo = post.user! //getting userinfo
        self.userNickName.text = self.userInfo.name
        let sourceDate = String(describing: post.created!)
        //formatting date to yyyy-mm-dd
        let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
        self.postDate.text = finalDate
        self.postDescription.text = post.postDescription
        self.isPhoto = post.isPhoto
        self.userLikedThisPost()
        self.countPostLikes()
    }

    func userLikedThisPost() {
        let user = TypeUsersFromBackendlessUser.returnUser(backendlessUser: (backendless?.userService.currentUser)!)
        
        let whereClause = "post.objectId = '\(self.post.objectId!)' AND user.objectId = '\(user.objectId!)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause

        var error: Fault?

        let likesList = backendless?.data.of(PostLike.ofClass()).find(dataQuery, fault: &error)

        if (likesList!.data.count != 0) { //If user has liked this post already
            postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
        } else {
            postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
        }
    }

    func countPostLikes() {
        let whereClause = "post.objectId = '\(self.post.objectId!)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        var error: Fault?
        
        let likesList = backendless?.data.of(PostLike.ofClass()).find(dataQuery, fault: &error)
        likesCount = likesList!.data.count
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
