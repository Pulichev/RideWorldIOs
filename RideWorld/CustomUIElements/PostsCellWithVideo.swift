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
import SVProgressHUD
import Player

class PostsCellWithVideo: UITableViewCell {
   
   weak var delegateUserTaps: TappedUserDelegate? // for sending user info
   weak var delegateSpotInfoTaps: TappedSpotInfoDelegate? // when tapping go to spot info from alert
   weak var delegateLikeEvent: PostsCellLikeEventDelegate?
   
   var post: PostItem!
   
   @IBOutlet weak var userPhoto: RoundedImageView!
   @IBOutlet weak var userLoginHeaderButton: UIButton!
   
   @IBOutlet weak var spotPostMediaHeight: NSLayoutConstraint!
   @IBOutlet var spotPostMedia: MediaContainerView!
   var player = Player()
   
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
   var likesCountInt: Int! = 0
   @IBOutlet weak var openComments: UIButton!
   
   var postIsLiked: Bool!
   
   func initialize(with cachedCell: PostItemCellCache, _ post: PostItem) {
      self.post            = post
      
      userLoginHeaderButton.setTitle(post.userLogin, for: .normal)
      
      if post.userProfilePhoto90 != "" {
         userPhoto.kf.setImage(with: URL(string: post.userProfilePhoto90!))
      } else {
         userPhoto.image = UIImage(named: "noProfilePhoto")
      }
      
      postDate.text        = cachedCell.postDate
      postDescription.text = post.userLogin + " " + post.description
      customizeDescUserLogin()
      
      postIsLiked          = cachedCell.postIsLiked
      likesCountInt        = cachedCell.likesCount
      isLikedPhoto.image   = cachedCell.isLikedPhoto.image
      likesCount.text      = String(describing: cachedCell.likesCount)
      let commentsCount    = String(describing: cachedCell.commentsCount)
      openComments.setTitle(NSLocalizedString("Open commentaries ", comment: "") + "(\(commentsCount))", for: .normal)
      
      addDoubleTapGestureOnPostPhotos()
      addDoubleTapGestureOnUserPhoto()
      addTapGestureOnVideo()
   }
   
   func addDoubleTapGestureOnUserPhoto() {
      let tap = UITapGestureRecognizer(target:self, action:#selector(userInfoTapped))
      tap.numberOfTapsRequired = 1
      userPhoto.addGestureRecognizer(tap)
      userPhoto.isUserInteractionEnabled = true
   }
   
   func addDoubleTapGestureOnPostPhotos() {
      //adding method on spot main photo tap
      let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked)) //target was only self
      tap.numberOfTapsRequired = 2
      spotPostMedia.addGestureRecognizer(tap)
      spotPostMedia.isUserInteractionEnabled = true
      
      let tapOnFist = UITapGestureRecognizer(target:self, action:#selector(postLiked))
      tapOnFist.numberOfTapsRequired = 1
      isLikedPhoto.addGestureRecognizer(tapOnFist)
      isLikedPhoto.isUserInteractionEnabled = true
   }
   
   func addTapGestureOnVideo() {
      let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
      tapGestureRecognizer.numberOfTapsRequired = 1
      player.view.addGestureRecognizer(tapGestureRecognizer)
   }
   
   // MRK: - Video mute part
   var mutedImageLayer  : CALayer!
   var unmutedImageLayer: CALayer!
   
   func addSoundImage(isMuted: Bool) {
      var image: UIImage
      
      if isMuted {
         image = UIImage(named: "soundOff")!
      } else {
         image = UIImage(named: "soundOn")!
      }
      
      let soundStateImageView = UIImageView(image: image)
      soundStateImageView.layer.contentsGravity = kCAGravityBottomLeft
      soundStateImageView.contentMode = .bottomLeft
      soundStateImageView.frame = spotPostMedia.bounds
      
      if isMuted {
         dismissSoundImage(isMuted: false) // we can mute and fast (<2.0s) unmute
         mutedImageLayer = soundStateImageView.layer
         
         spotPostMedia.layer.addSublayer(mutedImageLayer)
         spotPostMedia.playerLayer = mutedImageLayer
         // dismiss in 2 secs
         DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.dismissSoundImage(isMuted: true)
         })
      } else {
         dismissSoundImage(isMuted: true) // we can mute and fast (<2.0s) unmute
         unmutedImageLayer = soundStateImageView.layer
         
         spotPostMedia.layer.addSublayer(unmutedImageLayer)
         spotPostMedia.playerLayer = unmutedImageLayer
         
         DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.dismissSoundImage(isMuted: false)
         })
      }
   }
   
   private func dismissSoundImage(isMuted: Bool) {
      if isMuted {
         mutedImageLayer?.removeFromSuperlayer()
      } else {
         unmutedImageLayer?.removeFromSuperlayer()
      }
   }
   
   @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
      if player.muted {
         player.muted = false
         addSoundImage(isMuted: false)
      } else {
         player.muted = true
         addSoundImage(isMuted: true)
      }
   }
   
   // MARK: - Like part
   var likeEventActive = false // true, when sending request
   
   @objc func postLiked() {
      if !likeEventActive {
         if !postIsLiked {
            self.swapLikeInfo()
            
            likeEventActive = true
            addNewLike() { isSucceded in
               if !isSucceded {
                  self.showAlertOfError()
                  self.swapLikeInfo()
               }
               
               self.likeEventActive = false
            }
         } else {
            self.swapLikeInfo()
            
            likeEventActive = true
            removeExistedLike() { isSucceded in
               if !isSucceded {
                  self.showAlertOfError()
                  self.swapLikeInfo()
               }
               
               self.likeEventActive = false
            }
         }
      }
   }
   
   private func swapLikeInfo() {
      // update cell
      if postIsLiked {
         self.postIsLiked = false
         self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
         self.likesCountInt = self.likesCountInt - 1
      } else {
         self.postIsLiked = true
         self.isLikedPhoto.image = UIImage(named: "respectActive.png")
         self.likesCountInt = self.likesCountInt + 1
      }
      
      self.likesCount.text = String(self.likesCountInt)
      
      // update cell cache
      if let del = self.delegateLikeEvent {
         del.postLikeEventFinished(for: self.post.key)
      }
   }
   
   func addNewLike(completion: @escaping (_ isSucceded: Bool) -> Void) {
      // init new like
      let currentUserId = UserModel.getCurrentUserId()
      let likePlacedTime = String(describing: Date())
      let newLike = LikeItem(who: currentUserId, what: post.key,
                             postWasAddedBy: post.addedByUser, at: likePlacedTime)
      Like.add(newLike) { isSucceded in
         completion(isSucceded)
      }
   }
   
   func removeExistedLike(completion: @escaping (_ isSucceded: Bool) -> Void) {
      let currentUserId = UserModel.getCurrentUserId()
      
      Like.remove(with: currentUserId, post) { isSucceded in
         completion(isSucceded)
      }
   }
   
   private func showAlertOfError() {
      let alert = UIAlertController(title: NSLocalizedString("Oops", comment: ""),
                                    message: NSLocalizedString("Some error occurred. Retry your like/removing like", comment: ""),
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      parentViewController?.present(alert, animated: true, completion: nil)
   }
   
   @IBAction func openAlert(_ sender: UIButton) {
      print("a")
      let alertController = UIAlertController(title: nil,
                                              message: NSLocalizedString("Actions", comment: ""),
                                              preferredStyle: .actionSheet)
      
      let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                       style: .cancel)
      
      alertController.addAction(cancelAction)
      
      let goToSpotInfoAction = UIAlertAction(title: NSLocalizedString("Go To Spot Info", comment: ""),
                                             style: .default)
      { action in
         self.goToSpotInfo()
      }
      
      alertController.addAction(goToSpotInfoAction)
      
      let reportAction = UIAlertAction(title: NSLocalizedString("Report post", comment: ""),
                                       style: .destructive)
      { action in
         self.openReportReasonEnterAlert()
      }
      
      alertController.addAction(reportAction)
      
      parentViewController?.present(alertController, animated: true) // you can see Core/UIViewExtensions
   }
   
   func openReportReasonEnterAlert() {
      let alertController = UIAlertController(title: NSLocalizedString("Report post", comment: ""), message: "", preferredStyle: .alert)
      
      let saveAction = UIAlertAction(title: NSLocalizedString("Send", comment: ""),
                                     style: .destructive,
                                     handler: { alert in
            let reasonTextField = alertController.textFields![0] as UITextField
            UserModel.addReportOnPost(with: self.post.key, reason: reasonTextField.text!)
      })
      
      let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default)
      
      alertController.addTextField { textField in
         textField.placeholder = NSLocalizedString("Enter reason..", comment: "")
      }
      
      alertController.addAction(saveAction)
      alertController.addAction(cancelAction)
      
      parentViewController?.present(alertController, animated: true, completion: nil)
   }
   
   @IBAction func userLoginHeaderButtonTapped(_ sender: UIButton) {
      goToUserProfile(tappedUserLogin: post.userLogin)
   }
   
   @objc func userInfoTapped() {
      goToUserProfile(tappedUserLogin: post.userLogin)
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
   
   func goToSpotInfo() {
      delegateSpotInfoTaps?.spotInfoTapped(with: post.spotId)
   }
   
   private func customizeDescUserLogin() {
      postDescription.customize { description in
         //Looks for userItem.login
         let loginTappedType = ActiveType.custom(pattern: "^\(post.userLogin)\\b")
         description.enabledTypes.append(loginTappedType)
         description.handleCustomTap(for: loginTappedType) { login in
            self.userInfoTapped()
         }
         
         description.customColor[loginTappedType] = UIColor.black
         
         postDescription.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .custom(pattern: "^\(self.post.userLogin)\\b"):
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
