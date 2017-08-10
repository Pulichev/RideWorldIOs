//
//  UserProfileController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 25.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation

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
         }
      }
   }
   
   var cameFromEdit = false
   
   @IBOutlet var userNameAndSename: UILabel!
   @IBOutlet var userProfilePhoto: RoundedImageView!
   @IBOutlet weak var editButton: UIButton!
   
   @IBOutlet weak var followersStackView: UIStackView! {
      didSet {
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(followersButtonTapped(_:)))
         followersStackView.addGestureRecognizer(tapGesture)
      }
   }
   
   @IBOutlet weak var followingStackView: UIStackView! {
      didSet {
         let tapGesture = UITapGestureRecognizer(target: self, action: #selector(followingButtonTapped(_:)))
         followingStackView.addGestureRecognizer(tapGesture)
      }
   }
   
   @IBOutlet var followersButton: UIButton!
   @IBOutlet var followingButton: UIButton!
   @IBOutlet weak var postsCount: UILabel!
   @IBOutlet weak var userBio: UITextView!
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
      initLoadingView()
      setLoadingScreen()
      
      let currentUserId = UserModel.getCurrentUserId()
      UserModel.getItemById(for: currentUserId,
                            completion: { fetchedUserItem in
                              self.userInfo = fetchedUserItem
      })
   }
   
   func initializeUserTextInfo() {
      self.userBio.text = self.userInfo.bioDescription
      self.userNameAndSename.text = self.userInfo.nameAndSename
      
      initialiseFollowing()
      initializeUserPostsCount()
   }
   
   private func initialiseFollowing() {
      UserModel.getFollowersCountString(
      userId: userInfo.uid) { countOfFollowersString in
         self.followersButton.setTitle(countOfFollowersString, for: .normal)
      }
      
      UserModel.getFollowingsCountString(
      userId: userInfo.uid) { countOfFollowingsString in
         self.followingButton.setTitle(countOfFollowingsString, for: .normal)
      }
   }
   
   private func initializeUserPostsCount() {
      Post.getPostsCount(for: userInfo.uid) { postsCount in
         self.postsCount.text = String(describing: postsCount)
      }
   }
   
   func initializeUserPhoto() {
      if userProfilePhoto != nil { // if we came not from user edit controller
         if (self.userInfo.photo150ref != nil) {
            self.userProfilePhoto.kf.setImage(
               with: URL(string: userInfo.photo150ref!)) //Using kf for caching images.
         }
      }
   }
   
   func initializePosts() {
      UserModel.getPosts(for: userInfo.uid) { posts in
         self.posts = posts
         self.removeLoadingScreen()
         self.userProfileCollection.reloadData()
      }
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
   
   @IBAction func followersButtonTapped(_ sender: Any) {
      fromFollowersOrFollowing = true
      performSegue(withIdentifier: "goToFollowersFromUserNode", sender: self)
   }
   
   @IBAction func followingButtonTapped(_ sender: Any) {
      fromFollowersOrFollowing = false
      performSegue(withIdentifier: "goToFollowersFromUserNode", sender: self)
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
         
      case "editUserProfile":
         let newEditProfileController = segue.destination as! EditProfileController
         newEditProfileController.userInfo = userInfo
         newEditProfileController.delegate = self
         
      case "goToFollowersFromUserNode":
         let newFollowersController = segue.destination as! FollowersController
         newFollowersController.userId = userInfo.uid
         newFollowersController.followersOrFollowingList = fromFollowersOrFollowing
         
      default: break
      }
   }
   
   // MARK: - when data loading
   var loadingView: LoadingProcessView!
   
   private func initLoadingView() {
      let width: CGFloat = 120
      let height: CGFloat = 30
      let x = (userProfileCollection.frame.width / 2) - (width / 2)
      let y = (userProfileCollection.frame.height / 2) - (height / 2)
         - (navigationController?.navigationBar.frame.height)!
      loadingView = LoadingProcessView(frame: CGRect(x: x, y: y, width: width, height: height))
      
      userProfileCollection.addSubview(loadingView)
   }
   
   var haveWeFinishedLoading = false // bool value have we loaded posts or not. Mainly for DZNEmptyDataSet
   
   // Set the activity indicator into the main view
   private func setLoadingScreen() {
      loadingView.show()
   }
   
   // Remove the activity indicator from the main view
   private func removeLoadingScreen() {
      loadingView.dismiss()
      haveWeFinishedLoading = true
   }
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
         let str = "Welcome"
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
      if haveWeFinishedLoading {
         let str = "You have no publications"
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      } else {
         let str = ""
         let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
         return NSAttributedString(string: str, attributes: attrs)
      }
   }
   
   func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
      if haveWeFinishedLoading {
         return Image.resize(sourceImage: UIImage(named: "no_photo.png")!, toWidth: CGFloat(300)).image
      } else {
         return Image.resize(sourceImage: UIImage(named: "PleaseWaitTxt.gif")!, toWidth: CGFloat(300)).image
      }
   }
}
