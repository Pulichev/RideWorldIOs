//
//  FollowersTableCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 14.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher

class FollowersCell: UITableViewCell {
   var currentUserId: String!
   
   @IBOutlet weak var nickName: UILabel!
   @IBOutlet weak var userImage: RoundedImageView!
   @IBOutlet weak var button: UIButton!
   
   var follower: UserItem! {
      didSet {
         self.nickName.text = follower.login
         self.initialiseUserPhoto()
         self.initialiseFollowButton()
      }
   }
   
   func initialiseUserPhoto() {
      self.userImage.image = UIImage(named: "grayRec.jpg")
      
      UserMedia.getURL(for: follower.uid, withSize: 90,
                       completion: { URL in
                        self.userImage.kf.setImage(with: URL) // Using kf for caching images.
      })
      
   }
   
   func initialiseFollowButton() {
      if follower.uid != User.getCurrentUserId() {
         User.isCurrentUserFollowing(this: self.follower.uid,
                                     completion: { isFollowing in
                                       if isFollowing {
                                          self.button.setTitle("Following", for: .normal)
                                       } else {
                                          self.button.setTitle("Follow", for: .normal)
                                       }
         })
      } else {
         self.button.isHidden = true
      }
   }
   
   @IBAction func followButtonTapped(_ sender: Any) {
      if button.currentTitle == "Follow" { // add or remove like
         User.addFollowing(to: follower.uid)
         User.addFollower(to: follower.uid)
      } else {
         User.removeFollowing(from: follower.uid)
         User.removeFollower(from: follower.uid)
      }
      
      self.swapFollowButtonTittle()
   }
   
   private func swapFollowButtonTittle() {
      if self.button.currentTitle == "Follow" {
         self.button.setTitle("Following", for: .normal)
      } else {
         self.button.setTitle("Follow", for: .normal)
      }
   }
}
