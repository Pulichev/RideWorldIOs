//
//  PostsCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import ActiveLabel

class PostsCellWithPhoto: UITableViewCell {
   
   weak var delegateUserTaps: TappedUserDelegate? // for sending user info
   weak var delegateSpotInfoTaps: TappedSpotInfoDelegate? // when tapping go to spot info from alert
   
   var post: PostItem! {
      didSet {
         openComments.setTitle("Open commentaries (\(post.commentsCount!))", for: .normal)
      }
   }
   var userInfo: UserItem! // user, who posted
   
   @IBOutlet weak var userPhoto: RoundedImageView!
   @IBOutlet weak var userLoginHeaderButton: UIButton!
   
   @IBOutlet weak var spotPostPhotoHeight: NSLayoutConstraint!
   @IBOutlet var spotPostPhoto: UIImageView!
   
   @IBOutlet weak var postDate: UILabel!
   @IBOutlet weak var postDescription: ActiveLabel! {
      didSet {
         postDescription.numberOfLines = 0
         postDescription.enabledTypes = [.mention, .hashtag, .url]
         postDescription.textColor = .black
         postDescription.mentionColor = .brown
         postDescription.hashtagColor = .purple
         postDescription.handleHashtagTap { hashtag in }
      }
   }
   
   @IBOutlet weak var isLikedPhoto: UIImageView!
   @IBOutlet weak var likesCount: UILabel!
   @IBOutlet weak var openComments: UIButton!
   
   var postIsLiked: Bool!
   
   var userLikedOrDeletedLike = false //using this to update cache if user liked or disliked post
   
   func initialize(with cachedCell: PostItemCellCache) {
      post                 = cachedCell.post
      userInfo             = cachedCell.userInfo
      
      userLoginHeaderButton.setTitle(userInfo.login, for: .normal)
      if userInfo.photo90ref != nil {
         userPhoto.kf.setImage(with: URL(string: userInfo.photo90ref!))
      }
      
      postDate.text        = cachedCell.postDate
      postDescription.text = userInfo.login + " " + cachedCell.postDescription
      customizeDescUserLogin()
      
      likesCount.text      = String(cachedCell.likesCount)
      postIsLiked          = cachedCell.postIsLiked
      
      isLikedPhoto.image   = cachedCell.isLikedPhoto.image
   }
   
   func addDoubleTapGestureOnUserPhoto() {
      let tap = UITapGestureRecognizer(target:self, action:#selector(userInfoTapped))
      tap.numberOfTapsRequired = 1
      userPhoto.addGestureRecognizer(tap)
      userPhoto.isUserInteractionEnabled = true
   }
   
   func addDoubleTapGestureOnPostPhotos() {
      //adding method on spot main photo tap
      let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:)))
      tap.numberOfTapsRequired = 2
      spotPostPhoto.addGestureRecognizer(tap)
      spotPostPhoto.isUserInteractionEnabled = true
   }
   
   func postLiked(_ sender: Any) {
      if (userLikedOrDeletedLike) { // it might be a situation when user liked and disliked posts with out scroll.
         userLikedOrDeletedLike = false
      } else {
         userLikedOrDeletedLike = true
      }
      
      if(!postIsLiked) {
         postIsLiked = true
         isLikedPhoto.image = UIImage(named: "respectActive.png")
         let countOfLikesInt = Int(likesCount.text!)
         likesCount.text = String(countOfLikesInt! + 1)
         addNewLike()
      } else {
         postIsLiked = false
         isLikedPhoto.image = UIImage(named: "respectPassive.png")
         let countOfLikesInt = Int(likesCount.text!)
         likesCount.text = String(countOfLikesInt! - 1)
         removeExistedLike()
      }
   }
   
   func addNewLike() {
      // init new like
      let currentUserId = UserModel.getCurrentUserId()
      let likePlacedTime = String(describing: Date())
      let newLike = LikeItem(who: currentUserId, what: post.key,
                             postWasAddedBy: post.addedByUser, at: likePlacedTime)
      Like.add(newLike)
   }
   
   func removeExistedLike() {
      let currentUserId = UserModel.getCurrentUserId()
      
      Like.remove(with: currentUserId, post)
   }
   
   @IBAction func openAlert(_ sender: UIButton) {
      print("a")
      let alertController = UIAlertController(title: nil, message: "Takes the appearance of the bottom bar if specified; otherwise, same as UIActionSheetStyleDefault.", preferredStyle: .actionSheet)
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
      
      alertController.addAction(cancelAction)
      
      let goToSpotInfoAction = UIAlertAction(title: "Go To Spot Info", style: .default) { action in
         self.goToSpotInfo()
      }
      
      alertController.addAction(goToSpotInfoAction)
      
      let reportAction = UIAlertAction(title: "Report rider", style: .destructive) { action in
         print(action)
      }
      
      alertController.addAction(reportAction)
      
      parentViewController?.present(alertController, animated: true) // you can see Core/UIViewExtensions
   }
   
   @IBAction func userLoginHeaderButtonTapped(_ sender: UIButton) {
      delegateUserTaps?.userInfoTapped(userInfo)
   }
   
   func userInfoTapped() {
      delegateUserTaps?.userInfoTapped(userInfo)
   }
   
   // from @username
   private func goToUserProfile(tappedUserLogin: String) {
      UserModel.getItemByLogin(
      for: tappedUserLogin) { fetchedUserItem in
         self.delegateUserTaps?.userInfoTapped(fetchedUserItem)
      }
   }
   
   func goToSpotInfo() {
      delegateSpotInfoTaps?.spotInfoTapped(with: post.spotId)
   }
   
   private func customizeDescUserLogin() {
      postDescription.customize { description in
         //Looks for userItem.login
         let loginTappedType = ActiveType.custom(pattern: "^\(userInfo.login)\\b")
         description.enabledTypes.append(loginTappedType)
         description.handleCustomTap(for: loginTappedType) { login in
            self.userInfoTapped()
         }
         
         description.customColor[loginTappedType] = UIColor.black
         
         postDescription.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .custom(pattern: "^\(self.userInfo.login)\\b"):
               atts[NSFontAttributeName] = UIFont(name: "CourierNewPS-BoldMT", size: 15)
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
