//
//  spotPostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class SpotPostsCell: UITableViewCell {
    var backendless: Backendless!
    
    var postId: String?
    
    @IBOutlet var spotPostMedia: UIView!
    var player: AVPlayer!
    
    @IBOutlet weak var postDate: UILabel!
    @IBOutlet weak var userNickName: UIButton!
    @IBOutlet weak var postDescription: UITextView!
    @IBOutlet weak var isLikedPhoto: UIImageView!
    @IBOutlet weak var likesCount: UILabel!
    var isPhoto: Bool!
    var postIsLiked: Bool!
    
    var userLikedOrDeletedLike = false //using this to update cache if user liked or disliked post
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        //Configure the view for the selected state
    }
    
    func addDoubleTapGestureOnPostPhotos() {
        //adding method on spot main photo tap
        let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:)))
        tap.numberOfTapsRequired = 2
        spotPostMedia.addGestureRecognizer(tap)
        spotPostMedia.isUserInteractionEnabled = true
    }
    
    func postLiked(_ sender: Any) {
        userLikedOrDeletedLike = true
        backendless = Backendless.sharedInstance()
        
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userLoggedInObjectId")
        
        if(!self.postIsLiked) {
            addNewLike(userId: userId!)
            
            self.postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! + 1)
        }
        else {
            removeExistedLike(userId: userId!)
            
            self.postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! - 1)
        }
    }
    
    func addNewLike(userId: String) {
        let postLike = PostLike()
        postLike.postId = self.postId
        postLike.userId = userId
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.backendless.persistenceService.of(PostLike.ofClass()).save(postLike)
        }
    }
    
    func removeExistedLike(userId: String) {
        let whereClause = "postId = '\(self.postId!)' AND userId = '\(userId)'"
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
}
