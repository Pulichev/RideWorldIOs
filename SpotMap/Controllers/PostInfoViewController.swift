//
//  PostInfoViewController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 18.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import Kingfisher
import ActiveLabel

class PostInfoViewController: UIViewController {
    var isCurrentUserProfile: Bool!
    var delegateDeleting: ForUpdatingUserProfilePosts?
    
    var postInfo: PostItem!
    var user: UserItem!
    
    @IBOutlet var spotPostMedia: UIView!
    var player: AVPlayer!
    
    @IBOutlet var postDate: UILabel!
    @IBOutlet var postTime: UILabel!
    @IBOutlet var userNickName: UILabel!
    @IBOutlet var postDescription: ActiveLabel!
    @IBOutlet var isLikedPhoto: UIImageView!
    @IBOutlet var likesCount: UILabel!
    var likesCountInt = 0
    
    var isPhoto: Bool!
    var postIsLiked: Bool!
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            if !self.isCurrentUserProfile {
                self.navigationItem.rightBarButtonItem = nil // hide delete button
            }
            
            self.postDescription.text = self.postInfo.description
            let sourceDate = String(describing: self.postInfo.createdDate)
            //formatting date to yyyy-mm-dd
            let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
            self.postDate.text = finalDate
            let finalTime = sourceDate[sourceDate.index(sourceDate.startIndex, offsetBy: 11)..<sourceDate.index(sourceDate.startIndex, offsetBy: 16)]
            self.postTime.text = finalTime
            self.userNickName.text = self.user.login
            
            self.countPostLikes()
            self.userLikedThisPost()
            self.addDoubleTapGestureOnPostMedia()
        }
        self._mainPartOfMediaref = "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" // will use it in media download
        self.addMediaToView()
        self.initializeDesc()
    }
    
    func addDoubleTapGestureOnPostMedia() {
        //adding method on spot main photo tap
        let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:))) //target was only self
        tap.numberOfTapsRequired = 2
        spotPostMedia.addGestureRecognizer(tap)
        spotPostMedia.isUserInteractionEnabled = true
    }
    
    func countPostLikes() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postInfo.key).child("likes")
        //catch if user liked this post
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            self.likesCountInt = snapshot.children.allObjects.count
            self.likesCount.text = String(describing: self.likesCountInt)
        })
    }
    
    func initializeDesc() {
        self.postDescription.numberOfLines = 0
        self.postDescription.enabledTypes = [.mention, .hashtag, .url]
        self.postDescription.textColor = .black
        self.postDescription.mentionColor = .brown
        self.postDescription.hashtagColor = .purple
        self.postDescription.handleMentionTap { mention in // mention is @userLogin
            self.goToUserProfile(tappedUserLogin: mention)
        }
        self.postDescription.handleHashtagTap { hashtag in
            // TODO:
        }
    }
    
    func userLikedThisPost() {
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postInfo.key).child("likes").child(currentUserId!)
        // catch if user liked this post
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            if (snapshot.value as? [String : Any]) != nil {
                self.postIsLiked = true
                self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            } else {
                self.postIsLiked = false
                self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            }
        })
    }
    
    func postLiked(_ sender: Any) {
        if(!self.postIsLiked) {
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! + 1)
            addNewLike()
            self.postIsLiked = true
        } else {
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! - 1)
            removeExistedLike()
            
            self.postIsLiked = false
        }
    }
    
    // MARK: - Add and remove like
    func addNewLike() {
        // init new like
        let currentUserId = User.getCurrentUserId()
        let placedTime = String(describing: Date())
        let newLike = LikeItem(who: currentUserId, what: self.postInfo.key, at: placedTime)
        
        Like.addToUserNode(newLike)
        Like.addToPostNode(newLike)
    }
    
    func removeExistedLike() {
        let currentUserId = User.getCurrentUserId()
        
        Like.removeFromUserNode(with: currentUserId, self.postInfo)
        Like.removeFromPostNode(with: currentUserId, self.postInfo)
    }
    
    func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
        if (!postIsLiked) {
            postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            likesCountInt += 1
        } else {
            postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            likesCountInt -= 1
        }
    }
    
    // MARK: - Add media
    func addMediaToView() {
        self.spotPostMedia.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
        
        //Downloading and caching media
        if self.postInfo.isPhoto {
            setImage()
        } else {
            setVideo()
        }
    }
    
    private var _mainPartOfMediaref: String!
    
    func setImage() {
        // download thumbnail first
        PostMedia.getImageURL(for: self.postInfo.spotId, self.postInfo.key, withSize: 10, completion: { imageURL in
            let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
            let processor = BlurImageProcessor(blurRadius: 0.1)
            imageViewForView.kf.setImage(with: imageURL, placeholder: nil, options: [.processor(processor)])
            
            DispatchQueue.main.async {
                self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
            }
            
            self.downloadOriginalImage()
        })
    }
    
    private func downloadOriginalImage() {
        PostMedia.getImageURL(for: self.postInfo.spotId, self.postInfo.key, withSize: 700,
                              completion: { imageURL in
                                let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
                                imageViewForView.kf.indicatorType = .activity
                                imageViewForView.kf.setImage(with: imageURL) //Using kf for caching images.
                                
                                DispatchQueue.main.async {
                                    self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                                }
        })
    }
    
    func setVideo() {
        downloadThumbnail()
    }
    
    private func downloadThumbnail() {
        PostMedia.getImageURL(for: self.postInfo.spotId, self.postInfo.key, withSize: 10,
                              completion: { imageURL in
                                let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
                                let processor = BlurImageProcessor(blurRadius: 0.1)
                                imageViewForView.kf.setImage(with: imageURL, placeholder: nil, options: [.processor(processor)])
                                imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                                
                                self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                                
                                self.downloadBigThumbnail()
        })
    }
    
    private func downloadBigThumbnail() {
        PostMedia.getImageURL(for: self.postInfo.spotId, self.postInfo.key, withSize: 270,
                              completion: { imageURL in
                                let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
                                let processor = BlurImageProcessor(blurRadius: 0.1)
                                imageViewForView.kf.setImage(with: imageURL, placeholder: nil, options: [.processor(processor)])
                                imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                                self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                                
                                self.downloadVideo()
        })
    }
    
    private func downloadVideo() {
        PostMedia.getVideoURL(for: self.postInfo.spotId, self.postInfo.key,
                              completion: { vidoeURL in
                                let assetForCache = AVAsset(url: vidoeURL)
                                self.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
                                let playerLayer = AVPlayerLayer(player: self.player)
                                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                                playerLayer.frame = self.spotPostMedia.bounds
                                
                                self.spotPostMedia.layer.addSublayer(playerLayer)
                                
                                self.player.play()
        })
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
        User.deletePost(fromUserNodeWith: self.user.uid, self.postInfo.key)
        Post.delete(with: self.postInfo.key)
        Spot.deletePost(for: self.postInfo.spotId, self.postInfo.key)
        
        // delete media
        if self.postInfo.isPhoto {
            self.deletePhoto()
        } else {
            self.deleteVideo()
        }
        
        // likes
        // i wont delete likes on current stage of app writing.
        // there will be not too big count of deleted posts i hope.
        
        // deleting data from collection
        if let del = delegateDeleting {
            del.postsDeleted(postId: self.postInfo.key)
        }
        // go back
        _ = navigationController?.popViewController(animated: true)
    }
    
    private func deletePhoto() {
        PostMedia.deletePhoto(for: self.postInfo.spotId, self.postInfo.key, withSize: 700)
        self.delete270and10thumbnails()
    }
    
    private func deleteVideo() {
        PostMedia.deleteVideo(for: self.postInfo.spotId, self.postInfo.key)
        self.delete270and10thumbnails()
    }
    
    private func delete270and10thumbnails() {
        PostMedia.deletePhoto(for: self.postInfo.spotId, self.postInfo.key, withSize: 270)
        PostMedia.deletePhoto(for: self.postInfo.spotId, self.postInfo.key, withSize: 10)
    }
    
    @IBAction func goToComments(_ sender: Any) {
        self.performSegue(withIdentifier: "goToCommentsFromPostInfo", sender: self)
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
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fromPostInfoToRidersProfile" {
            let newRidersProfileController = segue.destination as! RidersProfileController
            newRidersProfileController.ridersInfo = ridersInfoForSending
            newRidersProfileController.title = ridersInfoForSending.login
        }
        
        if segue.identifier == "fromPostInfoToUserProfile" {
            let userProfileController = segue.destination as! UserProfileController
            userProfileController.cameFromSpotDetails = true
        }
        
        if segue.identifier == "goToCommentsFromPostInfo" {
            let commentariesController = segue.destination as! CommentariesController
            commentariesController.postId = self.postInfo.key
            commentariesController.postDescription = self.postInfo.description
            commentariesController.postDate = self.postInfo.createdDate
            commentariesController.userId = self.postInfo.addedByUser
        }
    }
}
