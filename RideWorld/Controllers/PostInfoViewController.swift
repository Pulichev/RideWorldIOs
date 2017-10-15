//
//  PostInfoViewController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 18.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher
import ActiveLabel
import SVProgressHUD
//import Player

class PostInfoViewController: UIViewController {
   
   var postInfo: PostItem!
   
   var isCurrentUserProfile: Bool!
   var delegateDeleting: ForUpdatingUserProfilePosts?
   
   @IBOutlet var spotPostMedia: AVPlayerView!
   @IBOutlet weak var mediaContainerHeight: NSLayoutConstraint!
   
   var isPhoto: Bool!
   var player: AVPlayer!
   
   @IBOutlet var postDate: UILabel!
   @IBOutlet var postDescription: ActiveLabel! {
      didSet {
         postDescription.numberOfLines = 0
         postDescription.enabledTypes = [.mention, .hashtag, .url]
         postDescription.textColor = .black
         postDescription.mentionColor = .brown
         postDescription.hashtagColor = .purple
         postDescription.handleMentionTap { login in // mention is @userLogin
            self.goToUserProfile(with: login)
         }
         postDescription.handleHashtagTap { hashtag in }
      }
   }
   
   @IBOutlet var isLikedPhoto: UIImageView!
   @IBOutlet var likesCount: UILabel!
   var likesCountInt = 0
   var postIsLiked: Bool!
   @IBOutlet weak var openComments: UIButton!
   @IBOutlet weak var deleteButton: UIButton!
   @IBOutlet weak var userPhoto: RoundedImageView!
   @IBOutlet weak var userLoginHeaderButton: UIButton!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      DispatchQueue.main.async {
         if self.postInfo.addedByUser != UserModel.getCurrentUserId() {
            self.navigationItem.rightBarButtonItem = nil // hide delete button
         }
         
         self.postDescription.text = self.postInfo.userLogin + " " + self.postInfo.description
         self.customizeDescUserLogin()
         
         self.initLikesAndDislikes()
         
         self.initializeDate()
         self.addDoubleTapGestureOnUserPhoto()
         if !self.postInfo.isPhoto {
            self.addTapGestureOnVideo()
         }
         
         self.userLoginHeaderButton.setTitle(self.postInfo.userLogin, for: .normal)
         if self.postInfo.userProfilePhoto90 != "" {
            self.userPhoto.kf.setImage(with: URL(string: self.postInfo.userProfilePhoto90!))
         } else {
            self.userPhoto.image = UIImage(named: "noProfilePhoto")
         }
      }
      
      let width = view.frame.size.width
      let height = CGFloat(Double(width) * postInfo.mediaAspectRatio)
      mediaContainerHeight.constant = height
//      spotPostMedia.layoutIfNeeded()
      
      addMediaToView()
   }
   
   func addDoubleTapGestureOnUserPhoto() {
      let tapOnUser = UITapGestureRecognizer(target:self, action:#selector(goToPostAuthor))
      tapOnUser.numberOfTapsRequired = 1
      userPhoto.addGestureRecognizer(tapOnUser)
      userPhoto.isUserInteractionEnabled = true
   }
   
   private func addGestureForLikes() {
      let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked))
      tap.numberOfTapsRequired = 2
      spotPostMedia.addGestureRecognizer(tap)
      spotPostMedia.isUserInteractionEnabled = true
      
      let tapOnFist = UITapGestureRecognizer(target:self, action:#selector(postLiked))
      tapOnFist.numberOfTapsRequired = 1
      isLikedPhoto.addGestureRecognizer(tapOnFist)
      isLikedPhoto.isUserInteractionEnabled = true
   }
   
   func initializeDate() {
      postDate.text = DateTimeParser.getDateTime(from: postInfo.createdDate)
   }
   
   // MARK: - Video mute part
   private func addTapGestureOnVideo() {
      let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:)))
      tapGestureRecognizer.numberOfTapsRequired = 1
      spotPostMedia.addGestureRecognizer(tapGestureRecognizer)
   }
   
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
      
      if isMuted {
         dismissSoundImage(isMuted: false) // we can mute and fast (<2.0s) unmute
         mutedImageLayer = soundStateImageView.layer
         
         spotPostMedia.layer.addSublayer(mutedImageLayer)
         
         // dismiss in 2 secs
         DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
            self.dismissSoundImage(isMuted: true)
         })
      } else {
         dismissSoundImage(isMuted: true) // we can mute and fast (<2.0s) unmute
         unmutedImageLayer = soundStateImageView.layer
         
         spotPostMedia.layer.addSublayer(unmutedImageLayer)
         
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
      if player.isMuted {
         player.isMuted = false
         addSoundImage(isMuted: false)
      } else {
         player.isMuted = true
         addSoundImage(isMuted: true)
      }
   }
   
   // MARK: - Like part
   private func initLikesAndDislikes() {
      Post.getLikesAndCommentsCount(for: self.postInfo.key) { (likesCount, commentsCount) in
         self.likesCountInt = likesCount
         self.likesCount.text = String(describing: likesCount)
         let commentsCountString = String(describing: commentsCount)
         self.openComments.setTitle(NSLocalizedString("Open commentaries ", comment: "") + "(\(commentsCountString))", for: .normal)
         
         Like.isLikedByUser(self.postInfo.key) { isLiked in
            self.initLikeData(isLiked)
         }
         
         self.addGestureForLikes()
      }
   }
   
   func initLikeData(_ isLiked: Bool) {
      if isLiked {
         self.postIsLiked = true
         self.isLikedPhoto.image = UIImage(named: "respectActive.png")
      } else {
         self.postIsLiked = false
         self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
      }
      
      likeEventActive = false
   }
   
   var likeEventActive = true // true, when sending request
   
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
   }
   
   // MARK: - Add and remove like
   func addNewLike(completion: @escaping (_ isSucceded: Bool) -> Void) {
      // init new like
      let currentUserId = UserModel.getCurrentUserId()
      let placedTime = String(describing: Date())
      let newLike = LikeItem(who: currentUserId, what: postInfo.key,
                             postWasAddedBy: postInfo.addedByUser, at: placedTime)
      
      Like.add(newLike) { isSucceded in
         completion(isSucceded)
      }
   }
   
   func removeExistedLike(completion: @escaping (_ isSucceded: Bool) -> Void) {
      let currentUserId = UserModel.getCurrentUserId()
      
      Like.remove(with: currentUserId, postInfo) { isSucceded in
         completion(isSucceded)
      }
   }
   
   private func showAlertOfError() {
      let alert = UIAlertController(title: NSLocalizedString("Oops!", comment: ""),
                                    message: NSLocalizedString("Some error occurred. Retry your like/removing like", comment: ""),
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   @IBAction func userLoginHeaderButtonTapped(_ sender: UIButton) {
      goToPostAuthor()
   }
   
   @objc func goToPostAuthor() {
      goToUserProfile(with: self.postInfo.userLogin)
   }
   
   @IBAction func openAlert(_ sender: UIButton) {
      print("a")
      let alertController = UIAlertController(title: nil, message: NSLocalizedString("Actions", comment: ""),
                                              preferredStyle: .actionSheet)
      
      let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
      
      alertController.addAction(cancelAction)
      
      let goToSpotInfoAction = UIAlertAction(title: NSLocalizedString("Go To Spot Info", comment: ""), style: .default) { action in
         Spot.getItemById(for: self.postInfo.spotId) { spot in
            self.spotInfoForSending = spot
            self.performSegue(withIdentifier: "fromPostInfoToSpotInfo", sender: self)
         }
      }
      
      alertController.addAction(goToSpotInfoAction)
      
      let reportAction = UIAlertAction(title: NSLocalizedString("Report post", comment: ""), style: .destructive) { action in
         self.openReportReasonEnterAlert()
      }
      
      alertController.addAction(reportAction)
      
      present(alertController, animated: true) // you can see Core/UIViewExtensions
   }
   
   func openReportReasonEnterAlert() {
      let alertController = UIAlertController(title: NSLocalizedString("Report post", comment: ""), message: "", preferredStyle: .alert)
      
      let saveAction = UIAlertAction(title: NSLocalizedString("Send", comment: ""), style: .destructive, handler: { alert in
         let reasonTextField = alertController.textFields![0] as UITextField
         UserModel.addReportOnPost(with: self.postInfo.key, reason: reasonTextField.text!)
      })
      
      let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default)
      
      alertController.addTextField { textField in
         textField.placeholder = NSLocalizedString("Enter reason..", comment: "")
      }
      
      alertController.addAction(saveAction)
      alertController.addAction(cancelAction)
      
      present(alertController, animated: true, completion: nil)
   }
   
   // MARK: - Add media
   func addMediaToView() {
      spotPostMedia.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
      
      //Downloading and caching media
      if postInfo.isPhoto {
         setImage()
      } else {
         setVideo()
      }
   }
   
   private var _mainPartOfMediaref: String!
   
   func setImage() {
      let imageView = UIImageView()
      imageView.layer.contentsGravity = kCAGravityResize
      imageView.contentMode = .scaleAspectFill
      imageView.frame = spotPostMedia.bounds
      
      // blur for 10px thumbnail
      let blurProc01 = BlurImageProcessor(blurRadius: 0.1)
      
      let circularProgress = CircularProgress(on: spotPostMedia.bounds)
      spotPostMedia.addSubview(circularProgress.view)
      
      // download 10px thumbnail
      imageView.kf.setImage(
         with: URL(string: postInfo.mediaRef10),
         placeholder: UIImage(named: "grayRec.png"),
         options: [.processor(blurProc01)],
         completionHandler: { (image, error, cacheType, imageUrl) in
            let spotPostMediaLayer = self.spotPostMedia.layer
            spotPostMediaLayer.contents = imageView.image!.cgImage
            // download original
            imageView.kf.setImage(
               with: URL(string: self.postInfo.mediaRef700),
               placeholder: image, // 10px
               progressBlock: { receivedSize, totalSize in
                  let percentage = (Double(receivedSize) / Double(totalSize))
                  circularProgress.view.progress = percentage
            }, completionHandler: { (_, _, _, _) in
               let spotPostMediaLayer = self.spotPostMedia.layer
               spotPostMediaLayer.contents = imageView.image!.cgImage
               circularProgress.view.isHidden = true
            })
      })
   }
   
   func setVideo() {
      addPlaceHolder()
      downloadBigThumbnail()
   }
   
   func addPlaceHolder() {
      let placeholder = UIImageView()
      let placeholderImage = UIImage(named: "grayRec.png")
      placeholder.image = placeholderImage
      placeholder.layer.contentsGravity = kCAGravityResize
      placeholder.contentMode = .scaleAspectFill
      let spotPostMediaLayer = spotPostMedia.layer
      spotPostMediaLayer.contents = placeholderImage!.cgImage
   }
   
   private func downloadBigThumbnail() {
      // thumbnail!
      let imageViewForView = UIImageView()
      imageViewForView.kf.setImage(with: URL(string: postInfo.mediaRef700)) { (_, _, _, _) in
         imageViewForView.layer.contentsGravity = kCAGravityResize
         imageViewForView.contentMode = .scaleAspectFill
         let spotPostMediaLayer = self.spotPostMedia.layer
         spotPostMediaLayer.contents = imageViewForView.image!.cgImage
         
         self.downloadVideo()
      }
   }
   
   private func downloadVideo() {
      let asset = AVURLAsset(url: URL(string: postInfo.videoRef)!)
      
      player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
      player.isMuted = true
      let castedLayer = spotPostMedia.layer as! AVPlayerLayer
      castedLayer.player = player
      
      player.play()
      
      addSoundImage(isMuted: true)
      addTapGestureOnVideo()
      
      // for looping
      NotificationCenter.default.addObserver(self, selector: #selector(PostsCellWithVideo.playerItemDidReachEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
   }
   
   @objc func playerItemDidReachEnd(notification: Notification) {
      if notification.object as? AVPlayerItem == player?.currentItem {
         player.pause()
         player.seek(to: kCMTimeZero)
         player.play()
      }
   }
   
   // MARK: - Delete post part
   @IBAction func deletePost(_ sender: Any) {
      let alert = UIAlertController(title: NSLocalizedString("Attention!", comment: ""),
                                    message: NSLocalizedString("Are you sure that you want to delete this post?", comment: ""),
                                    preferredStyle: .alert)
      
      let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""),
                                       style: .destructive) { action in
                                          self.startDeleteTransaction()
      }
      
      let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""),
                                       style: .default)
      
      alert.addAction(deleteAction)
      alert.addAction(cancelAction)
      
      present(alert, animated: true, completion: nil)
   }
   
   private func startDeleteTransaction() {
      Post.remove(postInfo)
      
      // delete media
      if postInfo.isPhoto {
         deletePhoto()
      } else {
         deleteVideo()
      }
      
      // deleting data from collection
      if let del = delegateDeleting {
         del.postsDeleted(post: postInfo)
      }
      // go back
      _ = navigationController?.popViewController(animated: true)
   }
   
   private func deletePhoto() {
      PostMedia.deletePhoto(for: postInfo.spotId, postInfo.key, withSize: 700)
      delete270and10thumbnails()
   }
   
   private func deleteVideo() {
      PostMedia.deleteVideo(for: postInfo.spotId, postInfo.key)
      delete270and10thumbnails()
   }
   
   private func delete270and10thumbnails() {
      PostMedia.deletePhoto(for: postInfo.spotId, postInfo.key, withSize: 270)
      PostMedia.deletePhoto(for: postInfo.spotId, postInfo.key, withSize: 10)
   }
   
   @IBAction func goToComments(_ sender: Any) {
      performSegue(withIdentifier: "goToCommentsFromPostInfo", sender: self)
   }
   
   var ridersInfoForSending: UserItem!
   
   private func goToUserProfile(with tappedUserLogin: String) {
      if postInfo.userLogin == tappedUserLogin {
         _ = self.navigationController?.popViewController(animated: true) // go back
      } else {
         SVProgressHUD.show()
         
         UserModel.getItemByLogin(
         for: tappedUserLogin) { fetchedUserItem, _ in
            SVProgressHUD.dismiss()
            
            if let userItem = fetchedUserItem { // have we founded?
               if userItem.uid == UserModel.getCurrentUserId() {
                  self.performSegue(withIdentifier: "fromPostInfoToUserProfile", sender: self)
               } else {
                  self.ridersInfoForSending = userItem
                  self.performSegue(withIdentifier: "fromPostInfoToRidersProfile", sender: self)
               }
            } else { // if no user founded for tapped nickname
               self.showAlertThatUserLoginNotFounded(tappedUserLogin: tappedUserLogin)
            }
         }
      }
   }
   
   private func showAlertThatUserLoginNotFounded(tappedUserLogin: String) {
      let alert = UIAlertController(title: NSLocalizedString("Error!", comment: ""),
                                    message: NSLocalizedString("No user founded with login ", comment: "") +
         "\(tappedUserLogin)",
         preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   private func customizeDescUserLogin() {
      postDescription.customize { description in
         //Looks for userItem.login
         let loginTappedType = ActiveType.custom(pattern: "^\(self.postInfo.userLogin)\\b")
         description.enabledTypes.append(loginTappedType)
         description.handleCustomTap(for: loginTappedType) { login in
            self.goToUserProfile(with: login)
         }
         
         description.customColor[loginTappedType] = UIColor.black
         
         postDescription.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .custom(pattern: "^\(self.postInfo.userLogin)\\b"):
               atts[NSAttributedStringKey.font] = UIFont(name: "PTSans-Bold", size: 15)
            default: ()
            }
            
            return atts
         }
         
         description.handleMentionTap { mention in // mention is @userLogin
            self.goToUserProfile(with: mention)
         }
      }
   }
   
   var spotInfoForSending: SpotItem! // for going from alert to spot
   
   // MARK: - prepare for segue
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "fromPostInfoToRidersProfile":
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = ridersInfoForSending
         newRidersProfileController.title = ridersInfoForSending.login
         
      case "fromPostInfoToUserProfile":
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
         
      case "goToCommentsFromPostInfo":
         let commentariesController = segue.destination as! CommentariesController
         commentariesController.post = postInfo
         commentariesController.postDescription = postInfo.description
         commentariesController.postDate = postInfo.createdDate
         commentariesController.userId = postInfo.addedByUser
         
      case "fromPostInfoToSpotInfo":
         let spotInfoController = segue.destination as! SpotInfoController
         spotInfoController.spotInfo = spotInfoForSending
         
      default: break
      }
   }
}
