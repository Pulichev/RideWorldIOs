//
//  PostInfoViewController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 18.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class PostInfoViewController: UIViewController {
    var backendless: Backendless!
    
    var postInfo: SpotPost!
    var user: Users!
    
    @IBOutlet var spotPostMedia: UIView!
    var player: AVPlayer!
    
    @IBOutlet var postDate: UILabel!
    @IBOutlet var userNickName: UILabel!
    @IBOutlet var postDescription: UITextView!
    @IBOutlet var isLikedPhoto: UIImageView!
    @IBOutlet var likesCount: UILabel!
    var likesCountInt = Int()
    
    var isPhoto: Bool!
    var postIsLiked: Bool!
    
    var userLikedOrDeletedLike = false //using this to update cache if user liked or disliked post
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backendless = Backendless.sharedInstance()
        
        DispatchQueue.main.async {
            self.postDescription.text = self.postInfo.postDescription
            
            let sourceDate = String(describing: self.postInfo.created!)
            //formatting date to yyyy-mm-dd
            let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
            self.postDate.text = finalDate
            self.userNickName.text = self.user.name
            
            self.countPostLikes()
            self.userLikedThisPost()
            self.addDoubleTapGestureOnPostMedia()
        }
    }
    
    func addDoubleTapGestureOnPostMedia() {
        //adding method on spot main photo tap
        let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:))) //target was only self
        tap.numberOfTapsRequired = 2
        spotPostMedia.addGestureRecognizer(tap)
        spotPostMedia.isUserInteractionEnabled = true
    }
    
    func postLiked(_ sender: Any) {
        userLikedOrDeletedLike = true
        
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userLoggedInObjectId")
        
        if(!self.postIsLiked) {
            addNewLike(userId: userId!)
            
            self.postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! + 1)
        } else {
            removeExistedLike(userId: userId!)
            
            self.postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! - 1)
        }
    }
    
    func addNewLike(userId: String) {
        let postLike = PostLike()
        postLike.postId = self.postInfo.objectId!
        postLike.userId = userId
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.backendless.persistenceService.of(PostLike.ofClass()).save(postLike)
        }
    }
    
    func removeExistedLike(userId: String) {
        let whereClause = "postId = '\(self.postInfo.objectId!)' AND userId = '\(userId)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        DispatchQueue.global(qos: .userInitiated).async {
            var error: Fault?
            //1) Finding postlike object of this cell
            let likesList = self.backendless.data.of(PostLike.ofClass()).find(dataQuery, fault: &error) //Finding
            //2) Delete this object from database
            self.backendless.persistenceService.of(PostLike.ofClass()).remove(likesList?.data[0]) //Deleting
        }
    }
    
    func userLikedThisPost() {
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userLoggedInObjectId")
        
        let whereClause = "postId = '\(self.postInfo.objectId!)' AND userId = '\(userId!)'"
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
        let whereClause = "postId = '\(self.postInfo.objectId!)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        var error: Fault?
        let likesList = backendless?.data.of(PostLike.ofClass()).find(dataQuery, fault: &error)
        likesCountInt = likesList!.data.count
        likesCount.text = String(likesCountInt)
    }
    
    func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
        if (!postIsLiked) { //If user has liked this post already
            postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            likesCountInt += 1
        } else {
            postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            likesCountInt -= 1
        }
    }
}
