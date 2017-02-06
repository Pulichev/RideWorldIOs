//
//  spotPostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
//  Using this class to cache text info from SpotPostCells

import Foundation

class SpotPostsCellCache
{
    var backendless = Backendless.sharedInstance()
    
    var postId = String()
    var userNickName = UILabel()
    var postDate = UILabel()
    var postDescription = UITextView()
    var isLikedPhoto = UIImageView()
    var postIsLiked = Bool()
    var likesCount = Int()
    
    func userLikedThisPost()
    {
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userLoggedInObjectId")
        
        let whereClause = "postId = '\(self.postId)' AND userId = '\(userId!)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        var error: Fault?
        let likesList = backendless?.data.of(PostLike.ofClass()).find(dataQuery, fault: &error)
        
        if(likesList!.data.count == 1) { //If user has liked this post already
            postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
        }
        else {
            postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
        }
    }
    
    func countPostLikes()
    {
        let whereClause = "postId = '\(self.postId)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        var error: Fault?
        let likesList = backendless?.data.of(PostLike.ofClass()).find(dataQuery, fault: &error)
        likesCount = likesList!.data.count
    }
}
