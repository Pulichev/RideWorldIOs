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

    func addNewLike() {
    
    }

    func removeExistedLike() {

    }
}
