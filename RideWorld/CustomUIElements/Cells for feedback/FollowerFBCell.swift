//
//  FollowerFBCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel

class FollowerFBCell: UITableViewCell { // FB = feedback
   weak var delegate: TappedUserDelegate? // for sending user info
   
   var userItem: UserItem! {
      didSet {
         userPhoto.image = UIImage(named: "grayRec.png") // default picture
         if let url = userItem.photo90ref {
            userPhoto?.kf.setImage(with: URL(string: url))
         } else {
            userPhoto?.setImage(string: self.userItem.login, color: nil, circular: true,
                                textAttributes: [NSFontAttributeName: UIFont(name: "Roboto-Light", size: 20)])
         }
         
         initialiseFollowButton()
      }
   }
   
   // media
   @IBOutlet weak var userPhoto: RoundedImageView! {
      didSet {
         let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInfoTapped))
         userPhoto.isUserInteractionEnabled = true
         userPhoto.addGestureRecognizer(tapGestureRecognizer)
      }
   }
   
   // text info
   var descText: String! {
      didSet {
         desc.text = descText
         
         customizeDescUserLogin()
      }
   }
   
   @IBOutlet weak var desc: ActiveLabel!
   
   @IBOutlet weak var followButton: UIButton!
   @IBOutlet weak var dateTime: UILabel!
   
   private func initialiseFollowButton() {
      UserModel.isCurrentUserFollowing(this: userItem.uid) { isFollowing in
         if isFollowing {
            self.followButton.setTitle("Following", for: .normal)
         } else {
            self.followButton.setTitle("Follow", for: .normal)
         }
         
         self.followButton.isEnabled = true
      }
   }
   
   @IBAction func followButtonTapped(_ sender: UIButton) {
      if followButton.currentTitle == "Follow" { // add or remove like
         UserModel.addFollowing(to: userItem.uid)
         UserModel.addFollower(to: userItem.uid)
      } else {
         UserModel.removeFollowing(from: userItem.uid)
         UserModel.removeFollower(from: userItem.uid)
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
   
   private func customizeDescUserLogin() {
      desc.customize { description in
         //Looks for userItem.login
         let loginTappedType = ActiveType.custom(pattern: "^\(userItem.login)\\b")
         description.enabledTypes.append(loginTappedType)
         description.handleCustomTap(for: loginTappedType) { login in self.userInfoTapped() }
         description.customColor[loginTappedType] = UIColor.black
         
         desc.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .custom(pattern: "^\(self.userItem.login)\\b"):
               atts[NSFontAttributeName] = UIFont(name: "Roboto-Medium", size: 15)
            default: ()
            }
            
            return atts
         }
      }
   }
}
