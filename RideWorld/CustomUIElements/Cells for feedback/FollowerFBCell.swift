//
//  FollowerFBCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class FollowerFBCell: UITableViewCell { // FB = feedback
   weak var delegate: TappedUserDelegate? // for sending user info
   
   var userId: String! { // maybe userItem
      didSet {
         User.getItemById(for: userId) { user in
            self.userItem = user
            self.userPhoto?.kf.setImage(with: URL(
               string: user.photo90ref!))
            self.loginButton.setTitle(user.login,
                                      for: .normal)
            self.initialiseFollowButton()
         }
      }
   }
   
   var userItem: UserItem!
   
   // MARK: - @IBOutlets
   // media
   @IBOutlet weak var userPhoto: RoundedImageView! {
      didSet {
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInfoTapped))
         userPhoto.isUserInteractionEnabled = true
         userPhoto.addGestureRecognizer(tapGestureRecognizer)
      }
   }
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
   
   @IBAction func loginButtonTapped(_ sender: Any) {
      userInfoTapped()
   }
   
   func userInfoTapped() {
      delegate?.userInfoTapped(userItem)
   }
   
   private func swapFollowButtonTittle() {
      if followButton.currentTitle == "Follow" {
         followButton.setTitle("Following", for: .normal)
      } else {
         followButton.setTitle("Follow", for: .normal)
      }
   }
}
