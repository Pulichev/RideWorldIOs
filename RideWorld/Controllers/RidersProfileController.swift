//
//  RidersProfileController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 15.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation

class RidersProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
   var ridersInfo: UserItem!
   
   @IBOutlet var followButton: UIButton!
   
   @IBOutlet var userNameAndSename: UILabel!
   @IBOutlet var ridersBio: UITextView!
   @IBOutlet var ridersProfilePhoto: RoundedImageView!
   
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
   
   @IBOutlet var riderProfileCollection: UICollectionView!
   
   var posts = [PostItem]()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      initLoadingView()
      setLoadingScreen()
      
      DispatchQueue.main.async {
         self.initializeUserTextInfo() //async loading user
         self.initializeUserPhoto()
         self.initializePosts()
      }
      
      riderProfileCollection.emptyDataSetSource = self
      riderProfileCollection.emptyDataSetDelegate = self
   }
   
   private func initializeUserTextInfo() {
      ridersBio.text = ridersInfo.bioDescription
      userNameAndSename.text = ridersInfo.nameAndSename
      
      isCurrentUserFollowing() // this function also places title on button
      initialiseFollowing()
   }
   
   private func isCurrentUserFollowing() {
      User.isCurrentUserFollowing(this: ridersInfo.uid) { isFollowing in
         if isFollowing {
            self.followButton.setTitle("Following", for: .normal)
         } else {
            self.followButton.setTitle("Follow", for: .normal)
         }
         self.followButton.isEnabled = true
      }
   }
   
   private func initialiseFollowing() {
      User.getFollowersCountString(
      userId: ridersInfo.uid) { countOfFollowersString in
         self.followersButton.setTitle(countOfFollowersString, for: .normal)
      }
      
      User.getFollowingsCountString(
      userId: ridersInfo.uid) { countOfFollowingsString in
         self.followingButton.setTitle(countOfFollowingsString, for: .normal)
      }
   }
   
   func initializeUserPhoto() {
      if ridersProfilePhoto != nil { // if we came not from user edit controller
         if ridersInfo.photo150ref != nil {
            self.ridersProfilePhoto.kf.setImage(
               with: URL(string: ridersInfo.photo150ref!)) //Using kf for caching images.
         }
      }
   }
   
   func initializePosts() {
      User.getPostsIds(for: ridersInfo.uid) { postsIds in
         if postsIds != nil {
            var loadedPosts = [PostItem]()
            
            for postId in postsIds! {
               Post.getItemById(for: postId) { postItem in
                  if postItem != nil {
                     loadedPosts.append(postItem!)
                     
                     //if all posts loaded
                     if loadedPosts.count == postsIds?.count {
                        self.posts = loadedPosts.sorted(by: { $0.key > $1.key })
                        self.riderProfileCollection.reloadData()
                        self.removeLoadingScreen()
                     }
                  }
               }
            }
         }
      }
   }
   
   // MARK: -  CollectionView part
   func collectionView(_ collectionView: UICollectionView,
                       numberOfItemsInSection section: Int) -> Int {
      return posts.count
   }
   
   func collectionView(_ collectionView: UICollectionView,
                       cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(
         withReuseIdentifier: "ImageCollectionViewCell",
         for: indexPath as IndexPath) as! ImageCollectionViewCell
      
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
   
   func collectionView(_ collectionView: UICollectionView,
                       didSelectItemAt indexPath: IndexPath) {
      // handle tap events
      selectedCellId = indexPath.item
      performSegue(withIdentifier: "goToPostInfo", sender: self)
   }
   
   var selectedCellId: Int!
   
   // MARK: - Following logic
   @IBAction func followButtonTapped(_ sender: Any) {
      if followButton.currentTitle == "Follow" { // add or remove like
         User.addFollowing(to: ridersInfo.uid)
         User.addFollower(to: ridersInfo.uid)
      } else {
         User.removeFollowing(from: ridersInfo.uid)
         User.removeFollower(from: ridersInfo.uid)
      }
      
      swapFollowButtonTittle()
   }
   
   private var fromFollowersOrFollowing: Bool! // true - followers else following
   
   @IBAction func followersButtonTapped(_ sender: Any) {
      fromFollowersOrFollowing = true
      performSegue(withIdentifier: "goToFollowersFromRidersNode", sender: self)
   }
   
   @IBAction func followingButtonTapped(_ sender: Any) {
      fromFollowersOrFollowing = false
      performSegue(withIdentifier: "goToFollowersFromRidersNode", sender: self)
   }
   
   private func swapFollowButtonTittle() {
      if followButton.currentTitle == "Follow" {
         followButton.setTitle("Following", for: .normal)
      } else {
         followButton.setTitle("Follow", for: .normal)
      }
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "goToPostInfo":
         let newPostInfoController = (segue.destination as! PostInfoViewController)
         newPostInfoController.postInfo = posts[selectedCellId]
         newPostInfoController.user = ridersInfo
         newPostInfoController.isCurrentUserProfile = false
         
      case "goToFollowersFromRidersNode":
         let newFollowersController = segue.destination as! FollowersController
         newFollowersController.userId = ridersInfo.uid
         newFollowersController.followersOrFollowingList = fromFollowersOrFollowing
         
      default: break
      }
   }
   
   // MARK: - when data loading
   var loadingView: LoadingProcessView!
   
   private func initLoadingView() {
      let width: CGFloat = 120
      let height: CGFloat = 30
      let x = (riderProfileCollection.frame.width / 2) - (width / 2)
      let y = (riderProfileCollection.frame.height / 2) - (height / 2) - (navigationController?.navigationBar.frame.height)!
      loadingView = LoadingProcessView(frame: CGRect(x: x, y: y, width: width, height: height))
      
      riderProfileCollection.addSubview(loadingView)
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

// MARK: - DZNEmptyDataSet for empty data tables
extension RidersProfileController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
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
         let str = "Rider has no publications"
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
