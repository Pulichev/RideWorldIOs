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
        self.addMediaToView()
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
//        postLike.postId = self.postInfo.objectId!
//        postLike.userId = userId
        
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
    
    func addMediaToView() {
        self.spotPostMedia.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
        
        if self.postInfo.isPhoto {
            let postPhotoURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/SpotPostPhotos/" + (postInfo.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
            DispatchQueue.global(qos: .userInteractive).async(execute: {
                if let url = URL(string: postPhotoURL) {
                    if let data = NSData(contentsOf: url) {
                        let imageFromCache: UIImage = UIImage(data: data as Data)!
                        
                        DispatchQueue.main.async(execute: {
                            let imageViewForView = UIImageView(frame: self.spotPostMedia.bounds)
                            imageViewForView.image = imageFromCache
                            imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                            self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                        })
                    }
                }
            })
        } else {
            let postVideoURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/SpotPostVideos/" + (postInfo.objectId!).replacingOccurrences(of: "-", with: "") + ".m4v"
            if let url = URL(string: postVideoURL) {
                
                DispatchQueue.global(qos: .userInteractive).async(execute: {

                    self.makeThumbnailFirst(postId: self.postInfo.objectId!)
                    
                    let assetForCache = AVAsset(url: url)
                    
                    DispatchQueue.main.async(execute: {
                        self.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
                        let playerLayer = AVPlayerLayer(player: self.player)
                        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                        playerLayer.frame = self.spotPostMedia.bounds
                        
                        self.spotPostMedia.layer.addSublayer(playerLayer)
                        
                        self.player.play()
                    })
                })
            }
        }
    }
    
    func makeThumbnailFirst(postId: String) {
        let thumbnailUrl = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/spotPostMediaThumbnails/" + postId.replacingOccurrences(of: "-", with: "") + ".jpeg"
        
        let url = URL(string: thumbnailUrl)
        let data = NSData(contentsOf: url!)
        let thumbnail: UIImage = UIImage(data: data as! Data)!
        
        DispatchQueue.main.async {
            // thumbnail
            let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
            imageViewForView.image = thumbnail
            imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
            self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
        }
    }
}
