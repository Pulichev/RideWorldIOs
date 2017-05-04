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
            
            DispatchQueue.global(qos: .userInitiated).async {
               self.initializeUserTextInfo()
               self.initializeUserPhoto()
            }
            
            DispatchQueue.global(qos: .background).async {
               self.initializePostsPhotos()
            }
         }
      }
   }
   
   var cameFromEdit = false
   
   @IBOutlet var userNameAndSename: UILabel!
   @IBOutlet var userBio: UITextView!
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
   
   @IBOutlet var userProfileCollection: UICollectionView! {
      didSet {
         userProfileCollection.emptyDataSetSource = self
         userProfileCollection.emptyDataSetDelegate = self
      }
   }
   
   var posts = [String: PostItem]()
   var postsImages = [String: UIImageView]()
   var postsIds = [String]() // need it to order by date
   
   var cameFromSpotDetails = false
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      editButton.isEnabled = false // blocking when no userInfo initialized
      setLoadingScreen()
      
      let currentUserId = User.getCurrentUserId()
      User.getItemById(for: currentUserId,
                       completion: { fetchedUserItem in
                        self.userInfo = fetchedUserItem
      })
   }
   
   func initializeUserTextInfo() {
      DispatchQueue.main.async {
         self.userBio.text = self.userInfo.bioDescription
         self.userNameAndSename.text = self.userInfo.nameAndSename
      }
      
      initialiseFollowing()
   }
   
   private func initialiseFollowing() {
      User.getFollowersCountString(
         userId: userInfo.uid,
         completion: { countOfFollowersString in
            self.followersButton.setTitle(countOfFollowersString, for: .normal)
      })
      
      User.getFollowingsCountString(
         userId: userInfo.uid,
         completion: { countOfFollowingsString in
            self.followingButton.setTitle(countOfFollowingsString, for: .normal)
      })
   }
   
   func initializeUserPhoto() {
      if userProfilePhoto != nil { // if we came not from user edit controller
         if (self.userInfo.photo150ref != nil) {
            self.userProfilePhoto.kf.setImage(with: URL(string: self.userInfo.photo150ref!)) //Using kf for caching images.
         }
      }
   }
   
   func initializePostsPhotos() {
      User.getPostsIds(for: userInfo.uid,
                       completion: { postsIds in
                        if postsIds != nil {
                           self.postsIds = postsIds!
                           
                           for postId in postsIds! {
                              Post.getItemById(for: postId,
                                               completion: { postItem in
                                                if postItem != nil {
                                                   self.posts[postId] = postItem
                                                   self.downloadPhotosAsync(post: postItem!)
                                                   
                                                   //if all posts loaded
                                                   if self.posts.count == postsIds?.count {
                                                      self.userProfileCollection.reloadData()
                                                      self.removeLoadingScreen()
                                                   }
                                                }
                              })
                           }
                        }
      })
   }
   
   private func downloadPhotosAsync(post: PostItem) {
      postsImages[post.key] = UIImageView(image: UIImage(named: "grayRec.jpg"))
      
      PostMedia.getImageData270x270(for: post,
                                    completion: { data in
                                       guard let imageData = UIImage(data: data!) else { return }
                                       let photoView = UIImageView(image: imageData)
                                       
                                       self.postsImages[post.key] = photoView
                                       
                                       DispatchQueue.main.async {
                                          self.userProfileCollection.reloadData()
                                       }
      })
   }
   
   // MARK: - CollectionView part
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return postsImages.count
   }
   
   func collectionView(_ collectionView: UICollectionView,
                       cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(
         withReuseIdentifier: "ImageCollectionViewCell", for: indexPath as IndexPath) as! ImageCollectionViewCell
      
      cell.postPicture.image = postsImages[postsIds[indexPath.row]]?.image!
      
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
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "goToPostInfoFromUserProfile":
         let newPostInfoController = segue.destination as! PostInfoViewController
         newPostInfoController.postInfo = posts[postsIds[selectedCellId]]
         newPostInfoController.user = userInfo
         newPostInfoController.isCurrentUserProfile = true
         newPostInfoController.delegateDeleting = self
         
      case "editUserProfile":
         let newEditProfileController = segue.destination as! EditProfileController
         newEditProfileController.userInfo = userInfo
         newEditProfileController.userPhoto = RoundedImageView(image: UIImage(named: "plus-512.gif"))
         if let image = userProfilePhoto.image {
            newEditProfileController.userPhotoTemp = image
         }
         newEditProfileController.delegate = self
         
      case "goToFollowersFromUserNode":
         let newFollowersController = segue.destination as! FollowersController
         newFollowersController.userId = userInfo.uid
         newFollowersController.followersOrFollowingList = fromFollowersOrFollowing
         
      default: break
      }
   }
   
   // MARK: - when data loading
   let loadingView = UIView() // View which contains the loading text and the spinner
   let spinner = UIActivityIndicatorView()
   let loadingLabel = UILabel()
   
   var haveWeFinishedLoading = false // bool value have we loaded posts or not. Mainly for DZNEmptyDataSet
   
   // Set the activity indicator into the main view
   private func setLoadingScreen() {
      let width: CGFloat = 120
      let height: CGFloat = 30
      let x = (userProfileCollection.frame.width / 2) - (width / 2)
      let y = (userProfileCollection.frame.height / 2) - (height / 2) - (navigationController?.navigationBar.frame.height)!
      loadingView.frame = CGRect(x: x, y: y, width: width, height: height)
      
      loadingLabel.textColor = UIColor.gray
      loadingLabel.textAlignment = NSTextAlignment.center
      loadingLabel.text = "Loading..."
      loadingLabel.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
      
      spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
      spinner.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
      spinner.startAnimating()
      
      loadingView.addSubview(spinner)
      loadingView.addSubview(loadingLabel)
      
      userProfileCollection.addSubview(loadingView)
   }
   
   // Remove the activity indicator from the main view
   private func removeLoadingScreen() {
      // Hides and stops the text and the spinner
      spinner.stopAnimating()
      loadingLabel.isHidden = true
      haveWeFinishedLoading = true
   }
}

// MARK: - Go/came to/from EditProfileController
extension UserProfileController: EditedUserInfoDelegate {
   func dataChanged(userInfo: UserItem, profilePhoto: UIImage) {
      cameFromEdit = true
      self.userInfo = userInfo
      userNameAndSename.text = userInfo.nameAndSename
      userBio.text = userInfo.bioDescription
      
      userProfilePhoto.image = profilePhoto
   }
}

extension UserProfileController: ForUpdatingUserProfilePosts {
   func postsDeleted(postId: String) {
      posts.removeValue(forKey: postId)
      postsImages.removeValue(forKey: postId)
      if let index = postsIds.index(of: postId) {
         postsIds.remove(at: index)
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
         return Image.resize(UIImage(named: "no_photo.png")!, targetSize: CGSize(width: 300.0, height: 300.0))
      } else {
         return Image.resize(UIImage(named: "PleaseWaitTxt.gif")!, targetSize: CGSize(width: 300.0, height: 300.0))
      }
   }
}

// MARK: - Part for hide and view navbar
extension UserProfileController {
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      if !cameFromSpotDetails {
         // Hide the navigation bar on the this view controller
         navigationController?.setNavigationBarHidden(true, animated: animated)
      }
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      if !cameFromSpotDetails {
         // Show the navigation bar on other view controllers
         navigationController?.setNavigationBarHidden(false, animated: animated)
      }
   }
}
