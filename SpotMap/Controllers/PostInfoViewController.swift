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
    
    // MARK: Add new like part
    private var newLike: LikeItem!
    private var userId: String!
    
    func addNewLike() {
        // init new like
        self.userId = User.getCurrentUserId()
        let likePlacedTime = String(describing: Date())
        self.newLike = LikeItem(userId: self.user.uid, postId: self.postInfo.key, likePlacedTime: likePlacedTime)
        
        Like.addToUserNode(self.newLike)
        Like.addToPostNode(self.newLike)
    }
    
    // MARK: Remove existing like part
    private var likeId: String! // value to construct refs for deleting
    
    func removeExistedLike() {
        self.userId = FIRAuth.auth()?.currentUser?.uid
        
        // we will remove it in reverse order
        removeLikeFromPostNode()
        removeLikeFromUserNode()
    }
    
    func removeLikeFromPostNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postInfo.key).child("likes").child(self.userId)
        // catch like id for delete next from likes Node
        likeRef.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            self.likeId = value?["likeId"] as? String ?? ""
            likeRef.removeValue()
        })
    }
    
    func removeLikeFromUserNode() {
        let likeRef = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.user.uid).child("likePlaced/onposts").child(self.postInfo.key)
        likeRef.removeValue()
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
    
    // MARK: ADD MEDIA
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
        let thumbnailUrl = _mainPartOfMediaref + self.postInfo.spotId + "/" + self.postInfo.key + "_resolution10x10.jpeg"
        let spotPostPhotoThumbnailURL = FIRStorage.storage().reference(forURL: thumbnailUrl)
        
        spotPostPhotoThumbnailURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
                let processor = BlurImageProcessor(blurRadius: 0.1)
                imageViewForView.kf.setImage(with: URL, placeholder: nil, options: [.processor(processor)])
                
                DispatchQueue.main.async {
                    self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                }
                
                self.downloadOriginalImage()
            }
        }
    }
    
    private func downloadOriginalImage() {
        let url = _mainPartOfMediaref + self.postInfo.spotId + "/" + self.postInfo.key + "_resolution700x700.jpeg"
        let spotDetailsPhotoURL = FIRStorage.storage().reference(forURL: url)
        
        spotDetailsPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
                imageViewForView.kf.indicatorType = .activity
                imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
                
                DispatchQueue.main.async {
                    self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                }
            }
        }
    }
    
    func setVideo() {
        downloadThumbnail()
    }
    
    private func downloadThumbnail() {
        let storage = FIRStorage.storage()
        let postKey = self.postInfo.key
        let url = _mainPartOfMediaref + self.postInfo.spotId + "/" + postKey + "_resolution10x10.jpeg"
        let spotVideoThumbnailURL = storage.reference(forURL: url)
        
        spotVideoThumbnailURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                // thumbnail!
                let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
                let processor = BlurImageProcessor(blurRadius: 0.1)
                imageViewForView.kf.setImage(with: URL!, placeholder: nil, options: [.processor(processor)])
                imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                
                self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                
                self.downloadBigThumbnail()
            }
        }
    }
    
    private func downloadBigThumbnail() {
        let storage = FIRStorage.storage()
        let postKey = self.postInfo.key
        let url = _mainPartOfMediaref  + self.postInfo.spotId + "/" + postKey + "_resolution270x270.jpeg"
        let spotVideoThumbnailURL = storage.reference(forURL: url)
        
        spotVideoThumbnailURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                // thumbnail!
                let imageViewForView = UIImageView(frame: self.spotPostMedia.frame)
                let processor = BlurImageProcessor(blurRadius: 0.1)
                imageViewForView.kf.setImage(with: URL!, placeholder: nil, options: [.processor(processor)])
                imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                
                self.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                
                self.downloadVideo()
            }
        }
    }
    
    private func downloadVideo() {
        let storage = FIRStorage.storage()
        let url = _mainPartOfMediaref + self.postInfo.spotId + "/" + self.postInfo.key + ".m4v"
        let spotVideoURL = storage.reference(forURL: url)
        
        spotVideoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                let assetForCache = AVAsset(url: URL!)
                self.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
                let playerLayer = AVPlayerLayer(player: self.player)
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                playerLayer.frame = self.spotPostMedia.bounds
                
                self.spotPostMedia.layer.addSublayer(playerLayer)
                
                self.player.play()
            }
        }
    }
    
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
        // delete from user posts node
        deleteFromUserPostNode()
        
        // delete from spotpost node
        let refToSpotPostNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost").child(self.postInfo.key)
        refToSpotPostNode.removeValue()
        
        // delete from spotdetails node
        deleteFromSpotDetailsNode()
        
        // delete media
        if self.postInfo.isPhoto {
            self.deletePhoto()
        } else {
            self.deleteVideo()
        }
        
        // likes
        // i wont delete likes on current stage of app writing.
        // there will be not too big count of deleted fight.
        
        // deleting data from collection
        if let del = delegateDeleting {
            del.postsDeleted(postId: self.postInfo.key)
        }
        // go back
        _ = navigationController?.popViewController(animated: true)
    }
    
    private func deleteFromUserPostNode() {
        let refToUserPostNode = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(self.user.uid).child("posts")
        refToUserPostNode.observeSingleEvent(of: .value, with: { snapshot in
            if var posts = snapshot.value as? [String : Bool] {
                posts.removeValue(forKey: self.postInfo.key)
                
                refToUserPostNode.setValue(posts)
            }
        })
    }
    
    private func deleteFromSpotDetailsNode() {
        let refToSpotDetailsNode = FIRDatabase.database().reference(withPath: "MainDataBase/spotDetails").child(self.postInfo.spotId).child("posts")
        refToSpotDetailsNode.observeSingleEvent(of: .value, with: { snapshot in
            if var posts = snapshot.value as? [String : Bool] {
                posts.removeValue(forKey: self.postInfo.key)
                
                refToSpotDetailsNode.setValue(posts)
            }
        })
    }
    
    private func deletePhoto() {
        let refToMedia = FIRStorage.storage().reference(withPath: "media/spotPostMedia").child(self.postInfo.spotId).child(self.postInfo.key + "_resolution700x700.jpeg")
        refToMedia.delete { (Error) in
            // do smth
        }
        
        delete270and10thumbnails()
    }
    
    private func deleteVideo() {
        let refToMedia = FIRStorage.storage().reference(withPath: "media/spotPostMedia").child(self.postInfo.spotId).child(self.postInfo.key + ".m4v")
        refToMedia.delete { (Error) in
            // do smth
        }
        
        delete270and10thumbnails()
    }
    
    private func delete270and10thumbnails() {
        var refToMedia = FIRStorage.storage().reference(withPath: "media/spotPostMedia").child(self.postInfo.spotId).child(self.postInfo.key + "_resolution270x270.jpeg")
        refToMedia.delete { (Error) in
            // do smth
        }
        
        refToMedia = FIRStorage.storage().reference(withPath: "media/spotPostMedia").child(self.postInfo.spotId).child(self.postInfo.key + "_resolution10x10.jpeg")
        refToMedia.delete { (Error) in
            // do smth
        }
    }
    
    @IBAction func goToComments(_ sender: Any) {
        self.performSegue(withIdentifier: "goToCommentsFromPostInfo", sender: self)
    }
    
    var ridersInfoForSending: UserItem!
    
    private func goToUserProfile(tappedUserLogin: String) {
        let refToAllUsers = FIRDatabase.database().reference(withPath: "MainDataBase/users")
        
        refToAllUsers.observeSingleEvent(of: .value, with: { snapshot in
            var isUserFounded = false
            
            for user in snapshot.children {
                let snapshotValue = (user as! FIRDataSnapshot).value as! [String: AnyObject]
                let login = snapshotValue["login"] as! String // getting login of user
                
                if login == tappedUserLogin {
                    isUserFounded = true
                    let tappedUser = UserItem(snapshot: user as! FIRDataSnapshot) // getting full user item
                    // check if going to current riders profile
                    if tappedUser.uid == self.user.uid {
                        _ = self.navigationController?.popViewController(animated: true) // go back
                    } else {
                        // 1 current user?
                        if tappedUser.uid == FIRAuth.auth()?.currentUser?.uid {
                            self.performSegue(withIdentifier: "fromPostInfoToUserProfile", sender: self)
                        } else { // 2 not current user
                            self.ridersInfoForSending = tappedUser
                            self.performSegue(withIdentifier: "fromPostInfoToRidersProfile", sender: self)
                        }
                    }
                }
            }
            
            if !isUserFounded { // if no user founded for tapped nickname
                let alert = UIAlertController(title: "Error!",
                                              message: "No user founded with nickname \(tappedUserLogin)",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
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
