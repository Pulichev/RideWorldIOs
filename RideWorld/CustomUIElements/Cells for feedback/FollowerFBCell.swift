//
//  FollowerFBCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class FollowerFBCell: UITableViewCell { // FB = feedback
   var userId: String! { // maybe userItem
      didSet {
         User.getItemById(for: userId) { user in
            self.userPhoto?.kf.setImage(with: URL(
               string: user.photo90ref!))
            self.loginButton.setTitle(user.login,
                                      for: .normal)
            self.initialiseFollowButton()
         }
      }
   }
   
   // MARK: - @IBOutlets
   // media
   @IBOutlet weak var userPhoto: RoundedImageView!
   // text info
   @IBOutlet weak var loginButton: UIButton!
   @IBOutlet weak var desc: UILabel!
   @IBOutlet weak var followButton: UIButton!
   @IBOutlet weak var dateTime: UILabel!
   
   private func initialiseFollowButton() {
      User.isCurrentUserFollowing(this: userId) { isFollowing in
         if isFollowing {
            self.followButton.setTitle("Following", for: .normal)
         } else {
            self.followButton.setTitle("Follow", for: .normal)
         }
      }
   }
   
   @IBAction func followButtonTapped(_ sender: UIButton) {
      if followButton.currentTitle == "Follow" { // add or remove like
         User.addFollowing(to: userId)
         User.addFollower(to: userId)
      } else {
         User.removeFollowing(from: userId)
         User.removeFollower(from: userId)
      }
      
      swapFollowButtonTittle()
   }
   
   private func swapFollowButtonTittle() {
      if followButton.currentTitle == "Follow" {
         followButton.setTitle("Following", for: .normal)
      } else {
         followButton.setTitle("Follow", for: .normal)
      }
   }
}
