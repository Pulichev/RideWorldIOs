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
    
    var postInfo: PostItem!
    var user: UserItem!
    
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
        
        DispatchQueue.main.async {
            self.postDescription.text = self.postInfo.description
            
            let sourceDate = String(describing: self.postInfo.createdDate)
            //formatting date to yyyy-mm-dd
            let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
            self.postDate.text = finalDate
            self.userNickName.text = self.user.login
            
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
        
    }
    
    func addNewLike() {
        
    }
    
    func removeExistedLike() {
        
    }
    
    func userLikedThisPost() {
        
    }
    
    func countPostLikes() {
        
    }
    
    func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
        
    }
    
    func addMediaToView() {
        
    }
    
    func makeThumbnailFirst(postId: String) {
    
    }
}
