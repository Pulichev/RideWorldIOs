//
//  PostsStripController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher
import ActiveLabel

class PostsStripController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
   @IBOutlet weak var tableView: UITableView! {
      didSet {
         tableView.delegate = self
         tableView.dataSource = self
         tableView.emptyDataSetSource = self
         tableView.emptyDataSetDelegate = self
      }
   }
   
   var refreshControl: UIRefreshControl! {
      didSet {
         refreshControl.attributedTitle = NSAttributedString(string: "Идет обновление...")
         refreshControl.addTarget(self, action: #selector(PostsStripController.refresh), for: UIControlEvents.valueChanged)
         tableView.addSubview(refreshControl)
         tableView.tableFooterView?.isHidden = true // hide on start
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
      
      refreshControl = UIRefreshControl()
      setLoadingScreen()
      
      self.loadPosts(completion: { newItems in
         self.appendLoadedPosts(newItems)
      })
   }
   
   // MARK: - Post load region
   func appendLoadedPosts(_ newItems: [PostItem]?) {
      var newItemsCache = [PostItemCellCache]()
      
      var countOfCachedCells = 0
      
      if newItems == nil { // no more posts
         self.removeLoadingScreen()
         self.tableView.reloadData() // for dzempty
         return
      }
      
      for newItem in newItems! {
         // need to cache all cells before adding
         _ = PostItemCellCache(spotPost: newItem,
                               completion: { cellCache in
                                 countOfCachedCells += 1
                                 newItemsCache.append(cellCache)
                                 
                                 if countOfCachedCells == newItems?.count {
                                    self.posts.append(contentsOf: newItems!)
                                    self.postItemCellsCache.append(contentsOf: newItemsCache)
                                    self.removeLoadingScreen()
                                    self.reloadNewCells(
                                       startingFrom: self.posts.count - countOfCachedCells,
                                       count: countOfCachedCells)
                                 }
         })
      }
   }
   
   private func reloadNewCells(startingFrom index: Int, count: Int) {
      var indexPaths = [IndexPath]()
      
      for i in index...(index + count - 1) {
         indexPaths.append(IndexPath(row: i, section: 0))
      }
      
      tableView.beginUpdates()
      tableView.insertRows(at: indexPaths, with: .none)
      tableView.endUpdates()
   }
   
   private func loadPosts(completion: @escaping (_ newItems: [PostItem]?) -> Void) {
      if cameFromSpotOrMyStrip {
         Spot.getPosts(for: spotDetailsItem.key, countOfNewItemsToAdd: postsLoadStep,
                       completion: { newItems in
                        completion(newItems)
         })
      } else {
         User.getStripPosts(countOfNewItemsToAdd: postsLoadStep,
                            completion: { newItems in
                              completion(newItems)
         })
      }
   }
   
   // MARK: - Load more posts region
   private let postsLoadStep = 5
   
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
         loadMoreStatus = true
         activityIndicator.startAnimating()
         tableView.tableFooterView?.isHidden = false
         
         loadMoreBegin(loadMoreEnd: {(x:Int) -> () in
            self.loadMoreStatus = false
            self.activityIndicator.stopAnimating()
            self.tableView.tableFooterView?.isHidden = true
         })
      }
   }
   
   func loadMoreBegin(loadMoreEnd: @escaping (Int) -> ()) {
      DispatchQueue.global(qos: .userInitiated).async {
         sleep(1)
         self.loadPosts(completion: { newItems in
            self.appendLoadedPosts(newItems)
            DispatchQueue.main.async {
               loadMoreEnd(0)
            }
         })
      }
   }
   
   // function for pull to refresh
   func refresh(sender: Any) {
      posts.removeAll()
      postItemCellsCache.removeAll()
      
      // clear our structs
      Spot.alreadyLoadedCountOfPosts = 0
      Spot.spotPostsIds.removeAll()
      
      User.alreadyLoadedCountOfPosts = 0
      User.postsIds.removeAll()
      
      loadPosts(completion: { newItems in
         self.appendLoadedPosts(newItems)
         // ending refreshing
         self.tableView.reloadData()
         self.refreshControl.endRefreshing()
      })
   }
   
   // MARK: - Main table filling region
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return posts.count
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
      cell.userNickName.addTarget(self, action: #selector(nickNameTapped), for: .touchUpInside)
      cell.openComments.tag     = row // for segue to send postId to comments
      cell.openComments.addTarget(self, action: #selector(goToComments), for: .touchUpInside)
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
      addPlaceHolder(cell: cell)
      
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
   
   func setImageOnCellFromCacheOrDownload(cell: PostsCell, cacheKey: Int) {
      if postItemCellsCache[cacheKey].isCached {
         PostMedia.getImageURL(for: posts[cacheKey].spotId,
                               posts[cacheKey].key, withSize: 700,
                               completion: { URL in
                                 let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                                 imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
                                 
                                 DispatchQueue.main.async {
                                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                                 }
                                 
         })
      } else {
         // download thumbnail first
         PostMedia.getImageURL(for: posts[cacheKey].spotId,
                               posts[cacheKey].key, withSize: 10,
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
      PostMedia.getImageURL(for: posts[cacheKey].spotId,
                            posts[cacheKey].key, withSize: 700,
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
      if (mediaCache.object(forKey: cacheKey) != nil) { // checking video existance in cache
         let cachedAsset = mediaCache.object(forKey: cacheKey) as? AVAsset
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
      PostMedia.getImageURL(for: posts[cacheKey].spotId,
                            posts[cacheKey].key, withSize: 10,
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
      PostMedia.getImageURL(for: posts[cacheKey].spotId,
                            posts[cacheKey].key, withSize: 270,
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
      PostMedia.getVideoURL(for: posts[cacheKey].spotId,
                            posts[cacheKey].key,
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
      performSegue(withIdentifier: "addNewPost", sender: self)
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
      
      present(alert, animated: true, completion: nil)
   }
   
   // go to riders profile
   func nickNameTapped(sender: UIButton!) {
      // check if going to current user
      if postItemCellsCache[sender.tag].userInfo.uid == User.getCurrentUserId() {
         performSegue(withIdentifier: "ifChoosedCurrentUser", sender: self)
      } else {
         ridersInfoForSending = postItemCellsCache[sender.tag].userInfo
         performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
      }
   }
   
   // go to comments
   func goToComments(sender: UIButton!) {
      postIdForSending = posts[sender.tag].key
      postDescForSending = posts[sender.tag].description
      postDateTimeForSending = posts[sender.tag].createdDate
      postUserIdForSending = posts[sender.tag].addedByUser
      performSegue(withIdentifier: "goToCommentsFromPostStrip", sender: self)
   }
   
   var ridersInfoForSending: UserItem!
   var postIdForSending: String!
   var postDescForSending: String!
   var postDateTimeForSending: String!
   var postUserIdForSending: String!
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "addNewPost":
         let newPostController = segue.destination as! NewPostController
         newPostController.spotDetailsItem = spotDetailsItem
         
      case "openRidersProfileFromSpotDetails":
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = ridersInfoForSending
         newRidersProfileController.title = ridersInfoForSending.login
         
      case "ifChoosedCurrentUser":
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
         
      case "goToCommentsFromPostStrip":
         let commentariesController = segue.destination as! CommentariesController
         commentariesController.postId = postIdForSending
         commentariesController.postDescription = postDescForSending
         commentariesController.postDate = postDateTimeForSending
         commentariesController.userId = postUserIdForSending
         
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
      let x = (tableView.frame.width / 2) - (width / 2)
      let y = (tableView.frame.height / 2) - (height / 2) - (navigationController?.navigationBar.frame.height)!
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
      
      tableView.addSubview(loadingView)
   }
   
   // Remove the activity indicator from the main view
   private func removeLoadingScreen() {
      // Hides and stops the text and the spinner
      spinner.stopAnimating()
      loadingLabel.isHidden = true
      haveWeFinishedLoading = true
   }
}

// MARK: - show/hide navigation bar
extension PostsStripController {
   //part for hide and view navbar from this navigation controller
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      if !cameFromSpotOrMyStrip {
         // Hide the navigation bar on the this view controller
         navigationController?.setNavigationBarHidden(true, animated: animated)
      }
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      // clear our structs
      Spot.alreadyLoadedCountOfPosts = 0
      Spot.spotPostsIds.removeAll()
      
      User.alreadyLoadedCountOfPosts = 0
      User.postsIds.removeAll()
      
      if !cameFromSpotOrMyStrip {
         // Show the navigation bar on other view controllers
         navigationController?.setNavigationBarHidden(false, animated: animated)
      }
   }
}

// MARK: - DZNEmptyDataSet for empty data tables
extension PostsStripController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
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
         let str = "Nothing to show."
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
