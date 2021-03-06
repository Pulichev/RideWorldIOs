//
//  FollowersCell.swift
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
  
  func initialiseUserPhoto() {
    userImage.image = UIImage(named: "grayRec.png")
    
    if follower.photo90ref != "" {
      userImage.kf.setImage(with: URL(string: follower.photo90ref!)) // Using kf for caching images.
    } else {
      userImage.image = UIImage(named: "noProfilePhoto")
    }
  }
  
  // MARK: - Follow part
  var follower: UserItem! {
    didSet {
      nickName.text = follower.login
      initialiseUserPhoto()
      initialiseFollowButton()
    }
  }
  
  func initialiseFollowButton() {
    if follower.uid != UserModel.getCurrentUserId() {
      UserModel.isCurrentUserFollowing(this: follower.uid) { isFollowing in
        if isFollowing {
          self.button.setTitle(NSLocalizedString("Following", comment: ""), for: .normal)
        } else {
          self.button.setTitle(NSLocalizedString("Follow", comment: ""), for: .normal)
        }
        
        self.button.isEnabled = true
      }
    } else {
      button.isHidden = true
    }
  }
  
  @IBAction func followButtonTapped(_ sender: Any) {
    if button.currentTitle == NSLocalizedString("Follow", comment: "") {
      UserModel.addFollowingAndFollower(to: follower.uid)
    } else {
      UserModel.removeFollowingAndFollower(from: follower.uid)
    }
    
    swapFollowButtonTittle()
  }
  
  private func swapFollowButtonTittle() {
    if button.currentTitle == NSLocalizedString("Follow", comment: "") {
      button.setTitle(NSLocalizedString("Following", comment: ""), for: .normal)
    } else {
      button.setTitle(NSLocalizedString("Follow", comment: ""), for: .normal)
    }
  }
}
