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
   
   var isCurrentUserProfile: Bool!
   var delegateDeleting: ForUpdatingUserProfilePosts?
   
   @IBOutlet var spotPostMedia: MediaContainerView!
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
   
   @IBOutlet weak var deleteButton: UIBarButtonItem!
   
   @IBOutlet weak var userPhoto: RoundedImageView!
   @IBOutlet weak var userLoginHeaderButton: UIButton!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      DispatchQueue.main.async {
         if !self.isCurrentUserProfile {
            self.navigationItem.rightBarButtonItem = nil // hide delete button
         }
         
         self.postDescription.text = self.postInfo.userLogin + " " + self.postInfo.description
         self.customizeDescUserLogin()
         
         Post.getLikesAndCommentsCount(for: self.postInfo.key) { (likesCount, commentsCount) in
            self.likesCount.text = String(describing: likesCount)
            let commentsCountString = String(describing: commentsCount)
            self.openComments.setTitle("Open commentaries (\(commentsCountString))", for: .normal)
            
            Like.isLikedByUser(self.postInfo.key) { isLiked in
               self.initLikeData(isLiked)
            }
         }

         self.initializeDate()
         self.addDoubleTapGestureOnPostMedia()
         
         self.userLoginHeaderButton.setTitle(self.postInfo.userLogin, for: .normal)
         if self.postInfo.userProfilePhoto90 != nil {
            self.userPhoto.kf.setImage(with: URL(string: self.postInfo.userProfilePhoto90!))
         }
      }
      
      let width = view.frame.size.width
      let height = CGFloat(Double(width) * postInfo.mediaAspectRatio)
      mediaContainerHeight.constant = height
      spotPostMedia.layoutIfNeeded()
      
      addMediaToView()
   }
   
   func addDoubleTapGestureOnPostMedia() {
      //adding method on post main photo tap
      let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:)))
      tap.numberOfTapsRequired = 2
      spotPostMedia.addGestureRecognizer(tap)
      spotPostMedia.isUserInteractionEnabled = true
      
      let tapOnFist = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:)))
      tapOnFist.numberOfTapsRequired = 1
      isLikedPhoto.addGestureRecognizer(tapOnFist)
      isLikedPhoto.isUserInteractionEnabled = true
      
      let tapOnUser = UITapGestureRecognizer(target:self, action:#selector(goToPostAuthor))
      tapOnUser.numberOfTapsRequired = 1
      userPhoto.addGestureRecognizer(tapOnUser)
      userPhoto.isUserInteractionEnabled = true
   }
   
   func initializeDate() {
      postDate.text = DateTimeParser.getDateTime(from: postInfo.createdDate)
   }
   
   func initLikeData(_ isLiked: Bool) {
      if isLiked {
         self.postIsLiked = true
         self.isLikedPhoto.image = UIImage(named: "respectActive.png")
      } else {
         self.postIsLiked = false
         self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
      }
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
   
   // MARK: - Add and remove like
   func addNewLike() {
      // init new like
      let currentUserId = UserModel.getCurrentUserId()
      let placedTime = String(describing: Date())
      let newLike = LikeItem(who: currentUserId, what: postInfo.key,
                             postWasAddedBy: postInfo.addedByUser, at: placedTime)
      
      Like.add(newLike)
   }
   
   func removeExistedLike() {
      let currentUserId = UserModel.getCurrentUserId()
      
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
   
   @IBAction func userLoginHeaderButtonTapped(_ sender: UIButton) {
      goToPostAuthor()
   }
   
   func goToPostAuthor() {
      goToUserProfile(with: self.postInfo.userLogin)
   }
   
   @IBAction func openAlert(_ sender: UIButton) {
      print("a")
      let alertController = UIAlertController(title: nil, message: "Actions", preferredStyle: .actionSheet)
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
      
      alertController.addAction(cancelAction)
      
      let goToSpotInfoAction = UIAlertAction(title: "Go To Spot Info", style: .default) { action in
         Spot.getItemById(for: self.postInfo.spotId) { spot in
            self.spotInfoForSending = spot
            self.performSegue(withIdentifier: "fromPostInfoToSpotInfo", sender: self)
         }
      }
      
      alertController.addAction(goToSpotInfoAction)
      
      let reportAction = UIAlertAction(title: "Report post", style: .destructive) { action in
         self.openReportReasonEnterAlert()
      }
      
      alertController.addAction(reportAction)
      
      present(alertController, animated: true) // you can see Core/UIViewExtensions
   }
   
   func openReportReasonEnterAlert() {
      let alertController = UIAlertController(title: "Report post", message: "", preferredStyle: .alert)
      
      let saveAction = UIAlertAction(title: "Send", style: .destructive, handler: { alert in
         let reasonTextField = alertController.textFields![0] as UITextField
         UserModel.addReportOnPost(with: self.postInfo.key, reason: reasonTextField.text!)
      })
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .default)
      
      alertController.addTextField { textField in
         textField.placeholder = "Enter reason.."
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
      
      spotPostMedia.layer.addSublayer(imageView.layer)
      spotPostMedia.playerLayer = imageView.layer
      
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
            // download original
            imageView.kf.setImage(
               with: URL(string: self.postInfo.mediaRef700),
               placeholder: image, // 10px
               progressBlock: { receivedSize, totalSize in
                  let percentage = (Double(receivedSize) / Double(totalSize))
                  circularProgress.view.progress = percentage
            }, completionHandler: { _ in
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
      placeholder.frame = spotPostMedia.bounds
      spotPostMedia.layer.addSublayer(placeholder.layer)
      spotPostMedia.playerLayer = placeholder.layer
   }
   
   private func downloadBigThumbnail() {
      // thumbnail!
      let imageViewForView = UIImageView()
      imageViewForView.kf.setImage(with: URL(string: postInfo.mediaRef700)) { _ in
         imageViewForView.layer.contentsGravity = kCAGravityResize
         imageViewForView.contentMode = .scaleAspectFill
         imageViewForView.frame = self.spotPostMedia.bounds
         
         self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
         self.spotPostMedia.playerLayer = imageViewForView.layer
         
         self.downloadVideo()
      }
   }
   
   private func downloadVideo() {
      let assetForCache = AVAsset(url: URL(string: postInfo.videoRef)!)
      
      player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
      let playerLayer = AVPlayerLayer(player: player)
      playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      playerLayer.frame = spotPostMedia.bounds
      
      spotPostMedia.layer.addSublayer(playerLayer)
      spotPostMedia.playerLayer = playerLayer
      
      player.play()
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
         UserModel.getItemByLogin(
         for: tappedUserLogin) { fetchedUserItem in
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
      let alert = UIAlertController(title: "Error!",
                                    message: "No user founded with nickname \(tappedUserLogin)",
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
               atts[NSFontAttributeName] = UIFont(name: "CourierNewPS-BoldMT", size: 15)
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
