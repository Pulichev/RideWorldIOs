//
//  RidersProfileController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 15.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import ReadMoreTextView
import Kingfisher

class RidersProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  
  weak var delegateFollowTaps: FollowTappedFromProfile? // if we come from feedback/followersList/followingsList
  // and tapped follow button -> update in parent controller
  
  var ridersInfo: UserItem!
  
  @IBOutlet var followButton: FollowButton!
  
  @IBOutlet var userNameAndSename: UILabel!
  @IBOutlet var ridersBio: ReadMoreTextView!
  @IBOutlet var ridersProfilePhoto: RoundedImageView!
  
  @IBOutlet weak var followersStackView: UIStackView!
  @IBOutlet weak var followingStackView: UIStackView!
  @IBOutlet weak var followedSpotsStackView: UIStackView!
  
  @IBOutlet var followersButton: UIButton!
  @IBOutlet var followingButton: UIButton!
  @IBOutlet weak var followedSpotsCount: UILabel!
  
  @IBOutlet weak var postsCount: UILabel!
  @IBOutlet weak var separatorLineConstraint: NSLayoutConstraint!
  
  @IBOutlet var riderProfileCollection: UICollectionView!
  
  var posts = [PostItem]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 1px line fix
    separatorLineConstraint.constant = 1 / UIScreen.main.scale // enforces it to be a true 1 pixel line
    
    initializeUserTextInfo()
    initializeUserPhoto()
    initializePosts()
    initGeturesRecognizersForFollowStackViews()
    
    riderProfileCollection.emptyDataSetSource = self
    riderProfileCollection.emptyDataSetDelegate = self
  }
  
  private func initializeUserTextInfo() {
    ridersBio.text = ridersInfo.bioDescription
    ridersBio.shouldTrim = true
    ridersBio.maximumNumberOfLines = 2
    let fontAttribute = [ NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 15)!,
                          NSAttributedStringKey.foregroundColor: UIColor.myLightGray() ]
    ridersBio.attributedReadMoreText = NSAttributedString(string: NSLocalizedString(" ...show more", comment: ""),
                                                          attributes: fontAttribute)
    ridersBio.attributedReadLessText = NSAttributedString(string: NSLocalizedString(" show less", comment: ""),
                                                          attributes: fontAttribute)
    
    ridersBio.text = ridersInfo.bioDescription
    userNameAndSename.text = ridersInfo.nameAndSename
    
    isCurrentUserFollowing() // this function also places title on button
    initialiseFollowing()
    initializeRiderPostsCount()
  }
  
  private func initializeRiderPostsCount() {
    Post.getPostsCount(for: ridersInfo.uid) { postsCount in
      self.postsCount.text = String(describing: postsCount)
    }
  }
  
  private func initializeUserPhoto() {
    if ridersProfilePhoto != nil { // if we came not from user edit controller
      if ridersInfo.photo150ref != "" {
        ridersProfilePhoto.kf.setImage(
          with: URL(string: ridersInfo.photo150ref!)) //Using kf for caching images.
      } else {
        ridersProfilePhoto.image = UIImage(named: "noProfilePhoto")
      }
    }
  }
  
  func initializePosts() {
    UserModel.getPosts(for: ridersInfo.uid) { posts in
      self.posts = posts
      self.haveWeFinishedLoading = true
      self.riderProfileCollection.reloadData()
    }
  }
  
  @IBAction func reloadButtonTapped(_ sender: Any) {
    initializePosts()
  }
  
  // MARK: - Following part
  private func isCurrentUserFollowing() {
    UserModel.isCurrentUserFollowing(this: ridersInfo.uid) { isFollowing in
      if isFollowing {
        self.followButton.setTitle(NSLocalizedString("Following", comment: ""), for: .normal)
      } else {
        self.followButton.setTitle(NSLocalizedString("Follow", comment: ""), for: .normal)
      }
      self.followButton.isEnabled = true
    }
  }
  
  private func initialiseFollowing() {
    UserModel.getFollowersCountString(
    userId: ridersInfo.uid) { countOfFollowersString in
      self.followersButton.setTitle(countOfFollowersString, for: .normal)
    }
    
    UserModel.getFollowingsCountString(userId: ridersInfo.uid) { countOfFollowingsString in
      self.followingButton.setTitle(countOfFollowingsString, for: .normal)
    }
    
    Spot.getSpotFollowingsByUserCount(with: ridersInfo.uid) { countOfFollowingsString in
      self.followedSpotsCount.text = countOfFollowingsString
    }
  }
  
  @IBAction func followButtonTapped(_ sender: Any) {
    if followButton.currentTitle == NSLocalizedString("Follow", comment: "") { // add or remove like
      UserModel.addFollowingAndFollower(to: ridersInfo.uid)
    } else {
      UserModel.removeFollowingAndFollower(from: ridersInfo.uid)
    }
    
    swapFollowButtonTittle()
    
    if let del = delegateFollowTaps {
      del.followTapped(on: ridersInfo.uid)
    }
  }
  
  private func swapFollowButtonTittle() {
    if followButton.currentTitle == NSLocalizedString("Follow", comment: "") {
      followButton.setTitle(NSLocalizedString("Following", comment: ""), for: .normal)
    } else {
      followButton.setTitle(NSLocalizedString("Follow", comment: ""), for: .normal)
    }
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
    performSegue(withIdentifier: "goToFollowersFromRidersNode", sender: self)
  }
  
  @IBAction func followingButtonTapped(_ sender: Any) {
    fromFollowersOrFollowing = false
    performSegue(withIdentifier: "goToFollowersFromRidersNode", sender: self)
  }
  
  @objc func followedSpotsTapped() {
    performSegue(withIdentifier: "fromRidersProfileToSpotFollowings", sender: self)
  }
  
  // MARK: -  CollectionView filling part
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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    switch segue.identifier! {
    case "goToPostInfo":
      let newPostInfoController = (segue.destination as! PostInfoController)
      newPostInfoController.postInfo = posts[selectedCellId]
      newPostInfoController.isCurrentUserProfile = false
      
    case "goToFollowersFromRidersNode":
      let newFollowersController = segue.destination as! FollowersController
      newFollowersController.userId = ridersInfo.uid
      newFollowersController.followersOrFollowingList = fromFollowersOrFollowing
      
    case "fromRidersProfileToSpotFollowings":
      let newSpotFollowingsController = segue.destination as! SpotFollowingsController
      newSpotFollowingsController.userId = ridersInfo.uid
      break
      
    default: break
    }
  }
  
  var haveWeFinishedLoading = false // bool value have we loaded posts or not. Mainly for DZNEmptyDataSet
}

// MARK: - DZNEmptyDataSet for empty data tables
extension RidersProfileController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
  func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    if haveWeFinishedLoading {
      let str = NSLocalizedString("Welcome", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
      return NSAttributedString(string: str, attributes: attrs)
    } else {
      let str = NSLocalizedString("Loading...", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PTSans-Bold", size: 22)]
      return NSAttributedString(string: str, attributes: attrs)
    }
  }
  
  func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
    if haveWeFinishedLoading {
      let str = NSLocalizedString("Rider has no publications", comment: "")
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
      return NSAttributedString(string: str, attributes: attrs)
    } else {
      let str = ""
      let attrs = [NSAttributedStringKey.font: UIFont(name: "PT Sans", size: 19.0)]
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
