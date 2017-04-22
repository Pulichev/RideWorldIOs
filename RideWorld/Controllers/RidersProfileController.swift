//
//  RidersProfileController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 15.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation

class RidersProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
   var ridersInfo: UserItem!
   
   @IBOutlet var userNameAndSename: UILabel!
   @IBOutlet var ridersBio: UITextView!
   @IBOutlet var ridersProfilePhoto: UIImageView!
   
   @IBOutlet var followButton: UIButton!
   
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
   
   var posts = [String: PostItem]()
   var postsImages = [String: UIImageView]()
   var postsIds = [String]() // need it to order by date
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      setLoadingScreen()
      
      DispatchQueue.main.async {
         self.initializeUserTextInfo() //async loading user
         self.initializeUserPhoto()
         self.initializeUserPostsPhotos()
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
      User.isCurrentUserFollowing(this: ridersInfo.uid,
                                  completion: { isFollowing in
                                    if isFollowing {
                                       self.followButton.setTitle("Following", for: .normal)
                                    } else {
                                       self.followButton.setTitle("Follow", for: .normal)
                                    }
                                    self.followButton.isEnabled = true
      })
   }
   
   private func initialiseFollowing() {
      User.getFollowersCountString(
         userId: ridersInfo.uid,
         completion: { countOfFollowersString in
            self.followersButton.setTitle(countOfFollowersString, for: .normal)
      })
      
      User.getFollowingsCountString(
         userId: ridersInfo.uid,
         completion: { countOfFollowingsString in
            self.followingButton.setTitle(countOfFollowingsString, for: .normal)
      })
   }
   
   func initializeUserPhoto() {
      if ridersProfilePhoto != nil { // if we came not from user edit controller
         UserMedia.getURL(for: ridersInfo.uid, withSize: 150,
                          completion: { url in
                           DispatchQueue.main.async {
                              self.ridersProfilePhoto.kf.setImage(with: url) //Using kf for caching images.
                              self.ridersProfilePhoto.layer.cornerRadius = self.ridersProfilePhoto.frame.size.height / 2
                           }
         })
      }
   }
   
   func initializeUserPostsPhotos() {
      User.getPostsIds(for: ridersInfo.uid,
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
                                                      self.riderProfileCollection.reloadData()
                                                      self.removeLoadingScreen()
                                                   }
                                                }
                              })
                           }
                        }
      })    }
   
   private func downloadPhotosAsync(post: PostItem) {
      postsImages[post.key] = UIImageView(image: UIImage(named: "grayRec.jpg"))
      
      PostMedia.getImageData270x270(for: post,
                                    completion: { data in
                                       guard let imageData = UIImage(data: data!) else { return }
                                       let photoView = UIImageView(image: imageData)
                                       
                                       self.postsImages[post.key] = photoView
                                       
                                       DispatchQueue.main.async {
                                          self.riderProfileCollection.reloadData()
                                       }
      })
   }
   
   // MARK: -  CollectionView part
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return postsImages.count
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RidersProfileCollectionViewCell", for: indexPath as IndexPath) as! RidersProfileCollectionViewCell
      
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
         newPostInfoController.postInfo = posts[postsIds[selectedCellId]]
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
   let loadingView = UIView() // View which contains the loading text and the spinner
   let spinner = UIActivityIndicatorView()
   let loadingLabel = UILabel()
   
   var haveWeFinishedLoading = false // bool value have we loaded posts or not. Mainly for DZNEmptyDataSet
   
   // Set the activity indicator into the main view
   private func setLoadingScreen() {
      let width: CGFloat = 120
      let height: CGFloat = 30
      let x = (riderProfileCollection.frame.width / 2) - (width / 2)
      let y = (riderProfileCollection.frame.height / 2) - (height / 2) - (navigationController?.navigationBar.frame.height)!
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
      
      riderProfileCollection.addSubview(loadingView)
   }
   
   // Remove the activity indicator from the main view
   private func removeLoadingScreen() {
      // Hides and stops the text and the spinner
      spinner.stopAnimating()
      loadingLabel.isHidden = true
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
