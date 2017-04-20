//
//  PostsStripController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseDatabase
import FirebaseAuth
import Kingfisher
import ActiveLabel

class PostsStripController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIScrollViewDelegate {
   @IBOutlet weak var tableView: UITableView! {
      didSet {
         self.tableView.delegate = self
         self.tableView.dataSource = self
         self.tableView.emptyDataSetSource = self
         self.tableView.emptyDataSetDelegate = self
      }
   }
   var refreshControl: UIRefreshControl! {
      didSet {
         self.refreshControl.attributedTitle = NSAttributedString(string: "Идет обновление...")
         self.refreshControl.addTarget(self, action: #selector(PostsStripController.refresh), for: UIControlEvents.valueChanged)
         tableView.addSubview(refreshControl)
         self.tableView.tableFooterView?.isHidden = true // hide on start
      }
   }
   @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
   
   var cameFromSpotOrMyStrip = false // true - from spot, default false - from mystrip
   
   var spotDetailsItem: SpotDetailsItem! // using it if come from spot
   
   private var posts = [PostItem]()
   private var postItemCellsCache = [PostItemCellCache]()
   
   private var mediaCache = NSMutableDictionary()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.refreshControl = UIRefreshControl()
      
      self.setLoadingScreen()
      
      self._mainPartOfMediaref = "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" // will use it in media download
      DispatchQueue.global(qos: .userInitiated).async {
         self.loadPosts()
      }
   }
   
   override func viewDidDisappear(_ animated: Bool) {
      Spot.alreadyLoadedCountOfPosts = 0
   }
   
   private func loadPosts() {
      if self.cameFromSpotOrMyStrip {
         self.loadSpotPosts()
      } else {
         self.loadMyStripPosts()
      }
   }
   
   // MARK: load posts region
   private let postsLoadStep = 5
   
   private func loadSpotPosts() {
      Spot.getPosts(for: self.spotDetailsItem.key, countOfNewItemsToAdd: self.postsLoadStep,
                    completion: { newItems in
                     if newItems != nil {
                        var newItemsCache = [PostItemCellCache]()
                        
                        for newItem in newItems! {
                           let newItemCache = PostItemCellCache(spotPost: newItem, stripController: self)
                           
                           newItemsCache.append(newItemCache)
                        }
                        
                        self.posts.append(contentsOf: newItems!)
                        self.postItemCellsCache.append(contentsOf: newItemsCache)
                        
                        self.removeLoadingScreen()
                     }
      })
   }
   
   private func loadMyStripPosts() {
      User.getStripPosts(countOfNewItemsToAdd: self.postsLoadStep,
                         completion: { newItems in
                           if newItems != nil {
                              var newItemsCache = [PostItemCellCache]()
                              
                              for newItem in newItems! {
                                 let newItemCache = PostItemCellCache(spotPost: newItem, stripController: self)
                                 
                                 newItemsCache.append(newItemCache)
                              }
                              
                              self.posts.append(contentsOf: newItems!)
                              self.postItemCellsCache.append(contentsOf: newItemsCache)
                              
                              self.removeLoadingScreen()
                           }
      })
   }
   
   func scrollViewDidScroll(_ scrollView: UIScrollView) {
      let currentOffset = scrollView.contentOffset.y
      let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
      let deltaOffset   = maximumOffset - currentOffset
      
      if deltaOffset <= 0 {
         if currentOffset > 0 { // if we are in the end
            loadMore()
         }
      }
   }
   
   private var loadMoreStatus = false
   
   func loadMore() {
      if !loadMoreStatus {
         self.loadMoreStatus = true
         self.activityIndicator.startAnimating()
         self.tableView.tableFooterView?.isHidden = false
         
         loadMoreBegin(loadMoreEnd: {(x:Int) -> () in
            self.loadMoreStatus = false
            self.activityIndicator.stopAnimating()
            self.tableView.tableFooterView?.isHidden = true
         })
      }
   }
   
   func loadMoreBegin(loadMoreEnd: @escaping (Int) -> ()) {
      DispatchQueue.global(qos: .userInitiated).async {
         //self.countOfPostsForGetting += self.dCountOfPostsForGetting
         self.loadPosts()
         sleep(2)
         
         DispatchQueue.main.async {
            loadMoreEnd(0)
         }
      }
   }
   
   // function for pull to refresh
   func refresh(sender: Any) {
      self.posts.removeAll()
      self.postItemCellsCache.removeAll()
      Spot.alreadyLoadedCountOfPosts = 0
      User.alreadyLoadedCountOfPosts = 0
      
      self.loadPosts()
      
      // ending refreshing
      self.tableView.reloadData()
      self.refreshControl.endRefreshing()
   }
   
   // Main table filling region
   func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.posts.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "PostsCell", for: indexPath) as! PostsCell
      let row = indexPath.row
      
      if cell.userLikedOrDeletedLike { // when cell appears checking if like was tapped
         cell.userLikedOrDeletedLike = false
         updateCellLikesCache(objectId: cell.post.key) // if yes updating cache
      }
      
      let cellFromCache = postItemCellsCache[row]
      cell.post                 = cellFromCache.post
      cell.userInfo             = cellFromCache.userInfo
      cell.userNickName.setTitle(cellFromCache.userNickName, for: .normal)
      cell.userNickName.tag     = row // for segue to send userId to ridersProfile
      cell.userNickName.addTarget(self, action: #selector(PostsStripController.nickNameTapped), for: .touchUpInside)
      cell.openComments.tag     = row // for segue to send postId to comments
      cell.openComments.addTarget(self, action: #selector(PostsStripController.goToComments), for: .touchUpInside)
      cell.postDate.text        = cellFromCache.postDate
      cell.postTime.text        = cellFromCache.postTime
      cell.postDescription.text = cellFromCache.postDescription
      cell.postDescription.handleMentionTap { mention in // mention is @userLogin
         self.goToUserProfile(tappedUserLogin: mention)
      }
      cell.likesCount.text      = String(cellFromCache.likesCount)
      cell.postIsLiked          = cellFromCache.postIsLiked
      cell.isPhoto              = cellFromCache.isPhoto
      cell.isLikedPhoto.image   = cellFromCache.isLikedPhoto.image
      setMediaOnCellFromCacheOrDownload(cell: cell, cacheKey: row) // cell.spotPostPhoto setting async
      cell.addDoubleTapGestureOnPostPhotos()
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
      let customCell = cell as! PostsCell
      if (!customCell.isPhoto && customCell.player != nil) {
         if (customCell.player.rate != 0 && (customCell.player.error == nil)) {
            // player is playing
            customCell.player.pause()
            customCell.player = nil
         }
      }
   }
   
   private func updateCellLikesCache(objectId: String) {
      for postCellCache in postItemCellsCache {
         if postCellCache.post.key == objectId {
            DispatchQueue.main.async {
               postCellCache.changeLikeToDislikeAndViceVersa()
            }
         }
      }
   }
   
   func setMediaOnCellFromCacheOrDownload(cell: PostsCell, cacheKey: Int) {
      cell.spotPostMedia.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
      self.addPlaceHolder(cell: cell)
      
      //Downloading and caching media
      if posts[cacheKey].isPhoto {
         setImageOnCellFromCacheOrDownload(cell: cell, cacheKey: cacheKey)
      } else {
         setVideoOnCellFromCacheOrDownload(cell: cell, cacheKey: cacheKey)
      }
   }
   
   func addPlaceHolder(cell: PostsCell) {
      let placeholderImage = UIImage(named: "grayRec.jpg")
      let placeholder = UIImageView(frame: cell.spotPostMedia.bounds)
      placeholder.image = placeholderImage
      placeholder.contentMode = .scaleAspectFill
      cell.spotPostMedia.layer.addSublayer(placeholder.layer)
   }
   
   private var _mainPartOfMediaref: String!
   
   func setImageOnCellFromCacheOrDownload(cell: PostsCell, cacheKey: Int) {
      if self.postItemCellsCache[cacheKey].isCached {
         PostMedia.getImageURL(for: self.posts[cacheKey].spotId,
                               self.posts[cacheKey].key, withSize: 700,
                               completion: { URL in
                                 let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                                 imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
                                 
                                 DispatchQueue.main.async {
                                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                                 }
                                 
         })
      } else {
         // download thumbnail first
         PostMedia.getImageURL(for: self.posts[cacheKey].spotId,
                               self.posts[cacheKey].key, withSize: 10,
                               completion: { URL in
                                 let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                                 let processor = BlurImageProcessor(blurRadius: 0.1)
                                 imageViewForView.kf.setImage(with: URL, placeholder: nil, options: [.processor(processor)])
                                 
                                 DispatchQueue.main.async {
                                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                                 }
                                 
                                 self.downloadOriginalImage(cell: cell, cacheKey: cacheKey)
         })
      }
   }
   
   private func downloadOriginalImage(cell: PostsCell, cacheKey: Int) {
      PostMedia.getImageURL(for: self.posts[cacheKey].spotId,
                            self.posts[cacheKey].key, withSize: 700,
                            completion: { URL in
                              let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                              imageViewForView.kf.indicatorType = .activity
                              imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
                              
                              DispatchQueue.main.async {
                                 self.postItemCellsCache[cacheKey].isCached = true
                                 cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                              }
      })
   }
   
   private func setVideoOnCellFromCacheOrDownload(cell: PostsCell, cacheKey: Int) {
      if (self.mediaCache.object(forKey: cacheKey) != nil) { // checking video existance in cache
         let cachedAsset = self.mediaCache.object(forKey: cacheKey) as? AVAsset
         cell.player = AVPlayer(playerItem: AVPlayerItem(asset: cachedAsset!))
         let playerLayer = AVPlayerLayer(player: (cell.player))
         playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
         playerLayer.frame = cell.spotPostMedia.bounds
         cell.spotPostMedia.layer.addSublayer(playerLayer)
         
         cell.player.play()
      } else {
         downloadThumbnail(cacheKey: cacheKey, cell: cell)
      }
   }
   
   private func downloadThumbnail(cacheKey: Int, cell: PostsCell) {
      PostMedia.getImageURL(for: self.posts[cacheKey].spotId,
                            self.posts[cacheKey].key, withSize: 10,
                            completion: { URL in
                              // thumbnail!
                              let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                              let processor = BlurImageProcessor(blurRadius: 0.1)
                              imageViewForView.kf.setImage(with: URL, placeholder: nil, options: [.processor(processor)])
                              imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                              
                              cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                              
                              self.downloadBigThumbnail(postKey: self.posts[cacheKey].key, cacheKey: cacheKey, cell: cell)
      })
   }
   
   private func downloadBigThumbnail(postKey: String, cacheKey: Int, cell: PostsCell) {
      PostMedia.getImageURL(for: self.posts[cacheKey].spotId,
                            self.posts[cacheKey].key, withSize: 270,
                            completion: { URL in                // thumbnail!
                              let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                              let processor = BlurImageProcessor(blurRadius: 0.1)
                              imageViewForView.kf.setImage(with: URL, placeholder: nil, options: [.processor(processor)])
                              imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                              
                              cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                              
                              self.downloadVideo(postKey: postKey, cacheKey: cacheKey, cell: cell)
      })
   }
   
   private func downloadVideo(postKey: String, cacheKey: Int, cell: PostsCell) {
      PostMedia.getVideoURL(for: self.posts[cacheKey].spotId,
                            self.posts[cacheKey].key,
                            completion: { vidoeURL in                 let assetForCache = AVAsset(url: vidoeURL)
                              self.mediaCache.setObject(assetForCache, forKey: cacheKey as NSCopying)
                              cell.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
                              let playerLayer = AVPlayerLayer(player: cell.player)
                              playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                              playerLayer.frame = cell.spotPostMedia.bounds
                              
                              cell.spotPostMedia.layer.addSublayer(playerLayer)
                              
                              cell.player.play()
      })
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
   }
   
   @IBAction func addNewPost(_ sender: Any) {
      self.performSegue(withIdentifier: "addNewPost", sender: self)
   }
   
   private func goToUserProfile(tappedUserLogin: String) {
      User.getItemByLogin(
         for: tappedUserLogin,
         completion: { fetchedUserItem in
            if let userItem = fetchedUserItem { // have we founded?
               if userItem.uid == User.getCurrentUserId() {
                  self.performSegue(withIdentifier: "ifChoosedCurrentUser", sender: self)
               } else {
                  self.ridersInfoForSending = userItem
                  self.performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
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
   
   // go to riders profile
   func nickNameTapped(sender: UIButton!) {
      // check if going to current user
      if self.postItemCellsCache[sender.tag].userInfo.uid == FIRAuth.auth()?.currentUser?.uid {
         self.performSegue(withIdentifier: "ifChoosedCurrentUser", sender: self)
      } else {
         self.ridersInfoForSending = self.postItemCellsCache[sender.tag].userInfo
         self.performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
      }
   }
   
   // go to comments
   func goToComments(sender: UIButton!) {
      self.postIdForSending = self.posts[sender.tag].key
      self.postDescForSending = self.posts[sender.tag].description
      self.postDateTimeForSending = self.posts[sender.tag].createdDate
      self.postUserIdForSending = self.posts[sender.tag].addedByUser
      self.performSegue(withIdentifier: "goToCommentsFromPostStrip", sender: self)
   }
   
   var ridersInfoForSending: UserItem!
   var postIdForSending: String!
   var postDescForSending: String!
   var postDateTimeForSending: String!
   var postUserIdForSending: String!
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == "addNewPost" {
         let newPostController = segue.destination as! NewPostController
         newPostController.spotDetailsItem = self.spotDetailsItem
      }
      
      if segue.identifier == "openRidersProfileFromSpotDetails" {
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = ridersInfoForSending
         newRidersProfileController.title = ridersInfoForSending.login
      }
      
      if segue.identifier == "ifChoosedCurrentUser" {
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
      }
      
      if segue.identifier == "goToCommentsFromPostStrip" {
         let commentariesController = segue.destination as! CommentariesController
         commentariesController.postId = self.postIdForSending
         commentariesController.postDescription = self.postDescForSending
         commentariesController.postDate = self.postDateTimeForSending
         commentariesController.userId = self.postUserIdForSending
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
      let x = (self.tableView.frame.width / 2) - (width / 2)
      let y = (self.tableView.frame.height / 2) - (height / 2) - (self.navigationController?.navigationBar.frame.height)!
      loadingView.frame = CGRect(x: x, y: y, width: width, height: height)
      
      self.loadingLabel.textColor = UIColor.gray
      self.loadingLabel.textAlignment = NSTextAlignment.center
      self.loadingLabel.text = "Loading..."
      self.loadingLabel.frame = CGRect(x: 0, y: 0, width: 140, height: 30)
      
      self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
      self.spinner.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
      self.spinner.startAnimating()
      
      loadingView.addSubview(self.spinner)
      loadingView.addSubview(self.loadingLabel)
      
      self.tableView.addSubview(loadingView)
   }
   
   // Remove the activity indicator from the main view
   private func removeLoadingScreen() {
      // Hides and stops the text and the spinner
      self.spinner.stopAnimating()
      self.loadingLabel.isHidden = true
      self.haveWeFinishedLoading = true
   }
}

// MARK: - show/hide navigation bar
extension PostsStripController {
   //part for hide and view navbar from this navigation controller
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      if !cameFromSpotOrMyStrip {
         // Hide the navigation bar on the this view controller
         self.navigationController?.setNavigationBarHidden(true, animated: animated)
      }
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      if !cameFromSpotOrMyStrip {
         // Show the navigation bar on other view controllers
         self.navigationController?.setNavigationBarHidden(false, animated: animated)
      }
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension PostsStripController {
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
         let str = "Nothing to show or its downloading at the moment. Wait.."
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
