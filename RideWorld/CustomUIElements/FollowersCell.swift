//
//  FollowersTableCell.swift
//  RideWorld
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
         nickName.text = follower.login
         initialiseUserPhoto()
         initialiseFollowButton()
      }
   }
   
   func initialiseUserPhoto() {
      userImage.image = UIImage(named: "grayRec.jpg")
      
      if follower.photo90ref != nil {
         self.userImage.kf.setImage(with: URL(string: follower.photo90ref!)) // Using kf for caching images.
      }
   }
   
   func initialiseFollowButton() {
      if follower.uid != User.getCurrentUserId() {
         User.isCurrentUserFollowing(this: follower.uid,
                                     completion: { isFollowing in
                                       if isFollowing {
                                          self.button.setTitle("Following", for: .normal)
                                       } else {
                                          self.button.setTitle("Follow", for: .normal)
                                       }
         })
      } else {
         button.isHidden = true
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
      
      swapFollowButtonTittle()
   }
   
   private func swapFollowButtonTittle() {
      if button.currentTitle == "Follow" {
         button.setTitle("Following", for: .normal)
      } else {
         button.setTitle("Follow", for: .normal)
      }
   }
}
