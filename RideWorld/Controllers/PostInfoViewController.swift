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

class PostInfoViewController: UIViewController {
   var postInfo: PostItem!
   var user: UserItem!
   
   var isCurrentUserProfile: Bool!
   var delegateDeleting: ForUpdatingUserProfilePosts?
   
   @IBOutlet var spotPostMedia: UIView!
   var isPhoto: Bool!
   var player: AVPlayer!
   
   @IBOutlet var postDate: UILabel!
   @IBOutlet var userNickName: UILabel!
   @IBOutlet var postDescription: ActiveLabel! {
      didSet {
         postDescription.numberOfLines = 0
         postDescription.enabledTypes = [.mention, .hashtag, .url]
         postDescription.textColor = .black
         postDescription.mentionColor = .brown
         postDescription.hashtagColor = .purple
         postDescription.handleMentionTap { mention in // mention is @userLogin
            self.goToUserProfile(tappedUserLogin: mention)
         }
         postDescription.handleHashtagTap { hashtag in }
      }
   }
   
   @IBOutlet var isLikedPhoto: UIImageView!
   @IBOutlet var likesCount: UILabel!
   var likesCountInt = 0
   var postIsLiked: Bool!
   @IBOutlet weak var openComments: UIButton!
   
   @IBOutlet weak var deleteButton: UIBarButtonItem!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      DispatchQueue.main.async {
         if !self.isCurrentUserProfile {
            self.navigationItem.rightBarButtonItem = nil // hide delete button
         }
         
         self.postDescription.text = self.postInfo.description
         self.userNickName.text = self.user.login
         self.countPostLikes()
         self.userLikedThisPost()
         self.initializeDate()
         self.addDoubleTapGestureOnPostMedia()
         self.setOpenCommentsButtonTittle()
      }
      
      addMediaToView()
   }
   
   func addDoubleTapGestureOnPostMedia() {
      //adding method on post main photo tap
      let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:)))
      tap.numberOfTapsRequired = 2
      spotPostMedia.addGestureRecognizer(tap)
      spotPostMedia.isUserInteractionEnabled = true
   }
   
   func initializeDate() {
      postDate.text = DateTimeParser.getDateTime(from: postInfo.createdDate)
   }
   
   func countPostLikes() {
      Post.getLikesCount(for: postInfo.key,
                         completion: { likesCount in
                           self.likesCountInt = likesCount
                           self.likesCount.text = String(describing: likesCount)
      })
   }
   
   func userLikedThisPost() {
      Post.isLikedByUser(postInfo.key,
                         completion: { isLiked in
                           if isLiked {
                              self.postIsLiked = true
                              self.isLikedPhoto.image = UIImage(named: "respectActive.png")
                           } else {
                              self.postIsLiked = false
                              self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
                           }
      })
   }
   
   func postLiked(_ sender: Any) {
      if(!postIsLiked) {
         isLikedPhoto.image = UIImage(named: "respectActive.png")
         let countOfLikesInt = Int(likesCount.text!)
         likesCount.text = String(countOfLikesInt! + 1)
         addNewLike()
         postIsLiked = true
      } else {
         isLikedPhoto.image = UIImage(named: "respectPassive.png")
         let countOfLikesInt = Int(likesCount.text!)
         likesCount.text = String(countOfLikesInt! - 1)
         removeExistedLike()
         
         postIsLiked = false
      }
   }
   
   private func setOpenCommentsButtonTittle() {
      openComments.setTitle("Open commentaries (\(postInfo.commentsCount!))", for: .normal)
   }
   
   // MARK: - Add and remove like
   func addNewLike() {
      // init new like
      let currentUserId = User.getCurrentUserId()
      let placedTime = String(describing: Date())
      let newLike = LikeItem(who: currentUserId, what: postInfo.key, postWasAddedBy: postInfo.addedByUser, at: placedTime)
      
      Like.add(newLike)
   }
   
   func removeExistedLike() {
      let currentUserId = User.getCurrentUserId()
      
      Like.remove(with: currentUserId, postInfo)
   }
   
   func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
      if (!postIsLiked) {
         postIsLiked = true
         isLikedPhoto.image = UIImage(named: "respectActive.png")
         likesCountInt += 1
      } else {
         postIsLiked = false
         isLikedPhoto.image = UIImage(named: "respectPassive.png")
         likesCountInt -= 1
      }
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
      // download thumbnail first
      let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
      let processor = BlurImageProcessor(blurRadius: 0.1)
      
      imageViewForView.kf.setImage(with: URL(string: postInfo.mediaRef10), placeholder: nil, options: [.processor(processor)]) //Using kf for caching images.
      DispatchQueue.main.async {
         self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
      }
      
      self.downloadOriginalImage()
   }
   
   private func downloadOriginalImage() {
      let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
      imageViewForView.kf.indicatorType = .activity

      imageViewForView.kf.setImage(with: URL(string: postInfo.mediaRef700)) //Using kf for caching images.
      DispatchQueue.main.async {
         self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
      }
   }
   
   func setVideo() {
      downloadThumbnail()
   }
   
   private func downloadThumbnail() {
      let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
      let processor = BlurImageProcessor(blurRadius: 0.1)
      
      imageViewForView.kf.setImage(with: URL(string: postInfo.mediaRef10), placeholder: nil, options: [.processor(processor)]) //Using kf for caching images.
      imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
      
      self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
      
      self.downloadBigThumbnail()
   }
   
   private func downloadBigThumbnail() {
      let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
      let processor = BlurImageProcessor(blurRadius: 0.1)
      
      imageViewForView.kf.setImage(with: URL(string: postInfo.mediaRef270), placeholder: nil, options: [.processor(processor)]) //Using kf for caching images.
      imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
      
      self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
      
      self.downloadVideo()
   }
   
   private func downloadVideo() {
      let assetForCache = AVAsset(url: URL(string: postInfo.videoRef)!)
      self.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
      let playerLayer = AVPlayerLayer(player: self.player)
      playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      playerLayer.frame = self.spotPostMedia.bounds
      
      self.spotPostMedia.layer.addSublayer(playerLayer)
      
      self.player.play()
   }
   
   // MARK: - Delete post part
   @IBAction func deletePost(_ sender: Any) {
      let alert = UIAlertController(title: "Attention!",
                                    message: "Are you sure that you want to delete this post?",
                                    preferredStyle: .alert)
      
      let deleteAction = UIAlertAction(title: "Delete",
                                       style: .destructive) { action in
                                          self.startDeleteTransaction()
      }
      
      let cancelAction = UIAlertAction(title: "Cancel",
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
         del.postsDeleted(postId: postInfo.key)
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
   
   private func goToUserProfile(tappedUserLogin: String) {
      User.getItemByLogin(
         for: tappedUserLogin,
         completion: { fetchedUserItem in
            if let userItem = fetchedUserItem { // have we founded?
               if fetchedUserItem?.uid == self.user.uid {
                  _ = self.navigationController?.popViewController(animated: true) // go back
               } else {
                  if userItem.uid == User.getCurrentUserId() {
                     self.performSegue(withIdentifier: "fromPostInfoToUserProfile", sender: self)
                  } else {
                     self.ridersInfoForSending = userItem
                     self.performSegue(withIdentifier: "fromPostInfoToRidersProfile", sender: self)
                  }
               }
            } else { // if no user founded for tapped nickname
               self.showAlertThatUserLoginNotFounded(tappedUserLogin: tappedUserLogin)
            }
      })
   }
   
   private func showAlertThatUserLoginNotFounded(tappedUserLogin: String) {
      let alert = UIAlertController(title: "Error!",
                                    message: "No user founded with nickname \(tappedUserLogin)",
         preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
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
         
      default: break
      }
   }
}
