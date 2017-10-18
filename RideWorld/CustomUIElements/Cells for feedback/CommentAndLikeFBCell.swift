//
//  CommentAndLikeFBCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel
import SVProgressHUD

class CommentAndLikeFBCell: UITableViewCell { // FB = feedback
  
  weak var delegateUserTaps: TappedUserDelegate? // for sending user info
  weak var delegatePostTaps: TappedPostDelegate? // for sending post info
  
  func initializeForComment(with commentFBItem: CommentFBItem) {
    self.userItem = commentFBItem.userItem
    self.postId = commentFBItem.postId
    self.postItem = commentFBItem.postItem!
    if commentFBItem.postAddedByUser == UserModel.getCurrentUserId() {
      self.descText = commentFBItem.userItem.login
        + NSLocalizedString(" commented your photo: ", comment: "")
        + commentFBItem.text
    } else { // for @userId not author
      self.descText = commentFBItem.userItem.login
        + NSLocalizedString(" mentioned you in comment: ", comment: "")
        + commentFBItem.text
    }
    
    self.dateTime.text = DateTimeParser.getDateTime(from: commentFBItem.dateTime)
  }
  
  func initializeForLike(with likeFBItem: LikeFBItem) {
    self.userItem = likeFBItem.userItem
    self.postId = likeFBItem.postId
    self.postItem = likeFBItem.postItem!
    self.descText = likeFBItem.userItem.login + NSLocalizedString(" liked your post.", comment: "")
    self.dateTime.text = DateTimeParser.getDateTime(from: likeFBItem.dateTime)
  }
  
  var userItem: UserItem! {
    didSet {
      if userItem.photo90ref != "" {
        userPhoto?.kf.setImage(with: URL(string: userItem.photo90ref!))
      } else {
        userPhoto?.image = UIImage(named: "noProfilePhoto")
      }
    }
  }
  
  var postAddedByUser: String!
  var postId: String!
  var postItem: PostItem! {
    didSet {
      postPhoto?.kf.setImage(with: URL(string: postItem.mediaRef70))
    }
  }
  
  @IBOutlet weak var userPhoto: RoundedImageView! {
    didSet {
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(userInfoTapped))
      userPhoto.isUserInteractionEnabled = true
      userPhoto.addGestureRecognizer(tapGestureRecognizer)
    }
  }
  
  @IBOutlet weak var postPhoto: UIImageView! {
    didSet {
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(postInfoTapped))
      postPhoto.isUserInteractionEnabled = true
      postPhoto.addGestureRecognizer(tapGestureRecognizer)
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
  @IBOutlet weak var dateTime: UILabel!
  
  // MARK: - Actions for segues to riders
  @objc func userInfoTapped() {
    delegateUserTaps?.userInfoTapped(userItem)
  }
  
  @objc func postInfoTapped() {
    delegatePostTaps?.postInfoTapped(postItem)
  }
  
  // from @username
  private func goToUserProfile(tappedUserLogin: String) {
    SVProgressHUD.show()
    
    UserModel.getItemByLogin(
    for: tappedUserLogin) { fetchedUserItem, _ in
      SVProgressHUD.dismiss()
      
      self.delegateUserTaps?.userInfoTapped(fetchedUserItem)
    }
  }
  
  private func customizeDescUserLogin() {
    desc.customize { description in
      //Looks for userItem.login
      let loginTappedType = ActiveType.custom(pattern: "^\(userItem.login)\\b")
      description.enabledTypes.append(loginTappedType)
      description.handleCustomTap(for: loginTappedType) { login in
        self.userInfoTapped()
      }
      description.customColor[loginTappedType] = UIColor.black
      
      desc.configureLinkAttribute = { (type, attributes, isSelected) in
        var atts = attributes
        switch type {
        case .custom(pattern: "^\(self.userItem.login)\\b"):
          atts[NSAttributedStringKey.font] = UIFont(name: "PTSans-Bold", size: 15)
        default: ()
        }
        
        return atts
      }
      
      description.handleMentionTap { mention in // mention is @userLogin
        self.goToUserProfile(tappedUserLogin: mention)
      }
    }
  }
}
