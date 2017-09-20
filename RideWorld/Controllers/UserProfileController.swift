//
//  UserProfileController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 25.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import ReadMoreTextView
import Kingfisher

class UserProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
   
   var userInfo: UserItem! {
      didSet {
         if !cameFromEdit { // when we came from edit
            // we have already updated info
            editButton.isEnabled = true
            self.navigationItem.title = userInfo.login
            
            self.initializeUserTextInfo()
            self.initializeUserPhoto()
            self.initializePosts()
            self.initGeturesRecognizersForFollowStackViews()
            self.followersButton.isEnabled = true
            self.followingButton.isEnabled = true
         }
      }
   }
   
   var cameFromEdit = false
   
   @IBOutlet var userNameAndSename: UILabel!
   @IBOutlet var userProfilePhoto: RoundedImageView!
   @IBOutlet weak var editButton: UIButton!
   
   @IBOutlet weak var followersStackView: UIStackView!
   @IBOutlet weak var followingStackView: UIStackView!
   @IBOutlet weak var followedSpotsStackView: UIStackView!
   
   @IBOutlet var followersButton: UIButton!
   @IBOutlet var followingButton: UIButton!
   @IBOutlet weak var followedSpotsCount: UILabel!
   
   @IBOutlet weak var postsCount: UILabel!
   @IBOutlet weak var userBio: ReadMoreTextView!
   @IBOutlet weak var separatorLineConstraint: NSLayoutConstraint!
   
   @IBOutlet var userProfileCollection: UICollectionView! {
      didSet {
         userProfileCollection.emptyDataSetSource = self
         userProfileCollection.emptyDataSetDelegate = self
      }
   }
   
   var posts = [PostItem]()
   
   var cameFromSpotDetails = false
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      // 1px line fix
      separatorLineConstraint.constant = 1 / UIScreen.main.scale // enforces it to be a true 1 pixel line
      
      editButton.isEnabled = false // blocking when no userInfo initialized
      
      let currentUserId = UserModel.getCurrentUserId()
      UserModel.getItemById(for: currentUserId,
                            completion: { fetchedUserItem in
                              self.userInfo = fetchedUserItem
      })
   }
   
   func initializeUserTextInfo() {
      userBio.text = userInfo.bioDescription
      userBio.shouldTrim = true
      userBio.maximumNumberOfLines = 2
      let fontAttribute = [ NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 15)!,
                            NSAttributedStringKey.foregroundColor: UIColor.myLightGray() ]
      userBio.attributedReadMoreText = NSAttributedString(string: NSLocalizedString(" ...show more", comment: ""), attributes: fontAttribute)
      userBio.attributedReadLessText = NSAttributedString(string: NSLocalizedString(" show less", comment: ""), attributes: fontAttribute)
      
      userNameAndSename.text = userInfo.nameAndSename
      
      initialiseFollowing()
      initializeUserPostsCount()
   }
   
   private func initialiseFollowing() {
      UserModel.getFollowersCountString(
      userId: userInfo.uid) { countOfFollowersString in
         self.followersButton.setTitle(countOfFollowersString, for: .normal)
      }
      
      UserModel.getFollowingsCountString(userId: userInfo.uid) { countOfFollowingsString in
         self.followingButton.setTitle(countOfFollowingsString, for: .normal)
      }
      
      Spot.getSpotFollowingsByUserCount(with: userInfo.uid) { countOfFollowingsString in
         self.followedSpotsCount.text = countOfFollowingsString
      }
   }
   
   private func initializeUserPostsCount() {
      Post.getPostsCount(for: userInfo.uid) { postsCount in
         self.postsCount.text = String(describing: postsCount)
      }
   }
   
   func initializeUserPhoto() {
      if userProfilePhoto != nil { // if we came not from user edit controller
         if userInfo.photo150ref != "" {
            userProfilePhoto.kf.setImage(
               with: URL(string: userInfo.photo150ref!)) //Using kf for caching images.
         } else {
            userProfilePhoto.image = UIImage(named: "noProfilePhoto")
         }
      }
   }
   
   func initializePosts() {
      UserModel.getPosts(for: userInfo.uid) { posts in
         self.posts = posts
         self.haveWeFinishedLoading = true
         self.userProfileCollection.reloadData()
      }
   }
   
   @IBAction func reloadButtonTapped(_ sender: Any) {
      initializePosts()
   }
   
   // MARK: - CollectionView part
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return posts.count
   }
   
   func collectionView(_ collectionView: UICollectionView,
                       cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(
         withReuseIdentifier: "ImageCollectionViewCell", for: indexPath as IndexPath) as! ImageCollectionViewCell
      
      cell.postPicture.kf.setImage(with: URL(string: posts[indexPath.row].mediaRef200))
      
      return cell
   }
   
   fileprivate let itemsPerRow: CGFloat = 3
   fileprivate let sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
   
   func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
      
      let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
      let availableWidth = view.frame.width - paddingSpace
      let widthPerItem = availableWidth / itemsPerRow
      
      return CGSize(width: widthPerItem, height: widthPerItem)
   }
   
   func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       insetForSectionAt section: Int) -> UIEdgeInsets {
      return sectionInsets
   }
   
   func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       minimumLineSpacingForSectionAt section: Int) -> CGFloat {
      return sectionInsets.left
   }
   
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      // handle tap events
      selectedCellId = indexPath.item
      performSegue(withIdentifier: "goToPostInfoFromUserProfile", sender: self)
   }
   
   var selectedCellId: Int!
   
   //MARK: - Buttons taps methods
   @IBAction func editProfileButtonTapped(_ sender: Any) {
      performSegue(withIdentifier: "editUserProfile", sender: self)
   }
   
   private var fromFollowersOrFollowing: Bool! // true - followers else following
   
   private func initGeturesRecognizersForFollowStackViews() {
      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(followersButtonTapped(_:)))
      followersStackView.addGestureRecognizer(tapGesture)
      
      let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(followingButtonTapped(_:)))
      followingStackView.addGestureRecognizer(tapGesture2)
      
      let tapGesture3 = UITapGestureRecognizer(target: self, action: #selector(followedSpotsTapped))
      followedSpotsStackView.addGestureRecognizer(tapGesture3)
   }
   
   @IBAction func followersButtonTapped(_ sender: Any) {
      fromFollowersOrFollowing = true
      performSegue(withIdentifier: "goToFollowersFromUserNode", sender: self)
   }
   
   @IBAction func followingButtonTapped(_ sender: Any) {
      fromFollowersOrFollowing = false
      performSegue(withIdentifier: "goToFollowersFromUserNode", sender: self)
   }
   
   @objc func followedSpotsTapped() {
      performSegue(withIdentifier: "fromUserProfileToSpotFollowings", sender: self)
   }
   
   @IBAction func logoutButtonTapped(_ sender: Any) {
      if UserModel.signOut() { // if no errors
         // then go to login
         performSegue(withIdentifier: "fromUserProfileToLogin", sender: self)
      }
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "goToPostInfoFromUserProfile":
         let newPostInfoController = segue.destination as! PostInfoViewController
         newPostInfoController.postInfo = posts[selectedCellId]
         newPostInfoController.isCurrentUserProfile = true
         newPostInfoController.delegateDeleting = self
         break
         
      case "editUserProfile":
         let newEditProfileController = segue.destination as! EditProfileController
         newEditProfileController.userInfo = userInfo
         newEditProfileController.delegate = self
         break
         
      case "goToFollowersFromUserNode": // this segue both for followers and followings
         let newFollowersController = segue.destination as! FollowersController
         newFollowersController.userId = userInfo.uid
         newFollowersController.followersOrFollowingList = fromFollowersOrFollowing
         break
         
      case "fromUserProfileToSpotFollowings":
         let newSpotFollowingsController = segue.destination as! SpotFollowingsController
         newSpotFollowingsController.userId = userInfo.uid
         break
         
      default: break
      }
   }
   
   var haveWeFinishedLoading = false // bool value have we loaded posts or not. Mainly for DZNEmptyDataSet
}

// MARK: - Go/came to/from EditProfileController
extension UserProfileController: EditedUserInfoDelegate {
   func dataChanged(userInfo: UserItem, profilePhoto: UIImage?) {
      cameFromEdit = true
      self.userInfo = userInfo
      userNameAndSename.text = userInfo.nameAndSename
      userBio.text = userInfo.bioDescription
      navigationItem.title = userInfo.login
      
      if profilePhoto != nil {
         userProfilePhoto.image = profilePhoto
      }
   }
}

extension UserProfileController: ForUpdatingUserProfilePosts {
   func postsDeleted(post: PostItem) {
      if let index = posts.index(where: { $0.key == post.key }) {
         posts.remove(at: index)
      }
      
      userProfileCollection.reloadData()
   }
}

// MARK: - DZNEmptyDataSet delegates
extension UserProfileController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
   func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = NSLocalizedString("Welcome", comment: "")
         let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = NSLocalizedString("Loading...", comment: "")
         let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = NSLocalizedString("You have no publications", comment: "")
         let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
      if haveWeFinishedLoading {
         return MyImage.resize(sourceImage: UIImage(named: "no_photo.png")!, toWidth: 200).image
      } else {
         return nil // Image.resize(sourceImage: UIImage(named: "PleaseWaitTxt.gif")!, toWidth: 200).image
      }
   }
}
