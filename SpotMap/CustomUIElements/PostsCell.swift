//
//  PostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import FirebaseDatabase
import FirebaseAuth

class PostsCell: UITableViewCell {
    var post: PostItem!
    var userInfo: UserItem! // user, who posted
    
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
        let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:))) //target was only self
        tap.numberOfTapsRequired = 2
        spotPostMedia.addGestureRecognizer(tap)
        spotPostMedia.isUserInteractionEnabled = true
    }
    
    func postLiked(_ sender: Any) {
        userLikedOrDeletedLike = true
        
        if(!self.postIsLiked) {
            self.postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! + 1)
            addNewLike()
        } else {
            self.postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! - 1)
            removeExistedLike()
        }
    }
    
    // MARK: Add new like part
    private var newLike: LikeItem!
    private var userId: String!
    
    func addNewLike() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/likes/onposts/").childByAutoId()
        
        // init new like
        let likeId = likeRef.key
        self.userId = FIRAuth.auth()?.currentUser?.uid
        let likePlacedTime = String(describing: Date())
        self.newLike = LikeItem(likeId: likeId, userId: self.userId, postId: self.post.key, likePlacedTime: likePlacedTime)
        
        addLikeToLikeNode()
        addLikeToUserNode()
        addLikeToPostNode()
    }
    
    func addLikeToLikeNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/likes/onposts/").child(newLike.likeId)
        likeRef.setValue(self.newLike.toAnyObject())
    }
    
    func addLikeToUserNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.userId!).child("likePlaced/onposts").child(self.post.key)
        likeRef.setValue(self.newLike.toAnyObject())
    }
    
    func addLikeToPostNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.post.key).child("likes").child(self.userId!)
        likeRef.setValue(self.newLike.toAnyObject())
    }
    
    // MARK: Remove existing like part
    private var likeId: String! // value to construct refs for deleting
    
    func removeExistedLike() {
        self.userId = FIRAuth.auth()?.currentUser?.uid
        
        // we will remove it in reverse order
        removeLikeFromPostNode()
        removeLikeFromUserNode()
    }
    
    func removeLikeFromPostNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.post.key).child("likes").child(self.userId!)
        // catch like id for delete next from likes Node
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            self.likeId = value?["likeId"] as? String ?? ""
            self.removeLikeFromLikeNode() // can do it only here cz of threading
            likeRef.removeValue()
        })
    }
    
    func removeLikeFromUserNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.userId!).child("likePlaced/onposts").child(self.post.key)
        likeRef.removeValue()
    }
    
    func removeLikeFromLikeNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/likes/onposts/").child(self.likeId)
        likeRef.removeValue()
    }
}
