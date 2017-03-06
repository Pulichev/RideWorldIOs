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
import FirebaseDatabase
import FirebaseAuth

class SpotPostsCell: UITableViewCell {
    var post: SpotPostItem!

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
            addNewLike()
            
            self.postIsLiked = true
            } else {
            removeExistedLike()

            self.postIsLiked = false
        }
    }

    private var likeId: String!
    
    func addNewLike() {
        addLikeToLikeNode()
        addLikeToUserNode()
        addLikeToPostNode()
    }
    
    func addLikeToLikeNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/likes/onposts/").childByAutoId()
        let likeRefKey = likeRef.key
        self.likeId = likeRefKey
        //save likeRef to global value. Will add it to other likes in other nodes
        let userId = FIRAuth.auth()?.currentUser?.uid
        let postId = post.key
        let likePlacedTime = String(describing: Date())
        let newLike = [
            "likeId" : self.likeId,
            "userId" : userId,
            "postId" : postId,
            "likePlacedTime" : likePlacedTime
            ] as [String : Any]
        likeRef.setValue(newLike)
    }
    
    func addLikeToUserNode() {
        let userId = FIRAuth.auth()?.currentUser?.uid
        let postId = post.key
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(userId!).child("likePlaced/onposts").child(postId)
        let likePlacedTime = String(describing: Date())
        let newLike = [
            "likeId" : self.likeId,
            "userId" : userId,
            "postId" : postId,
            "likePlacedTime" : likePlacedTime
            ] as [String : Any]
        likeRef.setValue(newLike)
    }
    
    func addLikeToPostNode() {
        let postId = post.key
        let userId = FIRAuth.auth()?.currentUser?.uid
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(postId).child("likes").child(userId!)
        let likePlacedTime = String(describing: Date())
        let newLike = [
            "likeId" : self.likeId,
            "userId" : userId,
            "postId" : postId,
            "likePlacedTime" : likePlacedTime
            ] as [String : Any]
        likeRef.setValue(newLike)
    }

    func removeExistedLike() {
        // we will remove it in reverse order
        removeLikeFromPostNode()
        removeLikeFromUserNode()
        removeLikeFromLikeNode()
    }
    
    func removeLikeFromPostNode() {
        let postId = post.key
        let userId = FIRAuth.auth()?.currentUser?.uid
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(postId).child("likes").child(userId!)
        //catch like id for delete nex from likes Node
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            self.likeId = value?["likeId"] as? String ?? ""
        })

        likeRef.removeValue()
    }
    
    func removeLikeFromUserNode() {
        let userId = FIRAuth.auth()?.currentUser?.uid
        let postId = post.key
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(userId!).child("likePlaced/onposts").child(postId)
        likeRef.removeValue()
    }
    
    func removeLikeFromLikeNode() {
        let postId = post.key
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/likes/onposts/").child(postId)
        likeRef.removeValue()
    }
}
