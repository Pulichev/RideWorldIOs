//
//  PostsStripController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseDatabase
import FirebaseStorage
import Kingfisher

class PostsStripController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIScrollViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    var refreshControl: UIRefreshControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var cameFromSpotOrMyStrip = false // true - from spot, default false - from mystrip
    
    var spotDetailsItem: SpotDetailsItem! // using it if come from spot
    
    private var _posts = [PostItem]()
    private var _postItemCellsCache = [PostItemCellCache]()
    
    private var _mediaCache = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
          
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Идет обновление...")
        self.refreshControl.addTarget(self, action: #selector(PostsStripController.refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        self.tableView.tableFooterView?.isHidden = true // hide on start
        
        self._mainPartOfMediaref = "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" // will use it in media download
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadPosts()
        }
    }
    
    private func loadPosts() {
        if self.cameFromSpotOrMyStrip {
            self.loadSpotPosts()
        } else {
            self.loadMyStripPosts() // TODO: add my own posts. Forgot about this
        }
    }
    
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
    
    // MARK: load posts region
    private var countOfPostsForGetting = 5 // start count is initialized here
    private var dCountOfPostsForGetting = 5
    private var countOfAlreadyLoadedPosts = 0
    
    private func loadSpotPosts() {
        //getting a list of keys of spot posts from spotdetails
        var posts = [PostItem]()
        var postsCache = [PostItemCellCache]()
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotdetails/" + self.spotDetailsItem.key + "/posts")
        
        ref.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if let keys = value?.allKeys as? [String] {
                let slicedAndOrderedByDateKeys = self.getSortedCurrentPartOfArray(keys: keys, startFromFirst: false)
                var count = 0 // count of loaded posts in this download operation
                for key in slicedAndOrderedByDateKeys { // for ordering by date desc
                    let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost/" + key)
                    
                    ref.observeSingleEvent(of: .value, with: { snapshot in
                        count += 1
                        let spotPostItem = PostItem(snapshot: snapshot)
                        let spotPostCellCache = PostItemCellCache(spotPost: spotPostItem, stripController: self) // stripController - we will update our tableview from another thread
                        
                        posts.append(spotPostItem)
                        postsCache.append(spotPostCellCache)
                        self.countOfAlreadyLoadedPosts += 1
                        
                        if (self.countOfAlreadyLoadedPosts == self.countOfPostsForGetting) || (count == slicedAndOrderedByDateKeys.count) { // проверить если постов меньше, чем 3, например
                            self.appendNewItems(posts: posts, postsCache: postsCache)
                            count = 0
                        }
                    }) { (error) in
                        print(error.localizedDescription)
                    }
                }
            }
        })
    }
    
    // TIP: - I will not review this func more. It will be badder for reading
    private func loadMyStripPosts() {
        // get list of my followings
        var posts = [PostItem]()                // new items that we will append to _posts
        var postsCache = [PostItemCellCache]()  // and _postItemCellsCache
        
        let currentUserId = FIRAuth.auth()?.currentUser?.uid
        let refToFollowings = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(currentUserId!).child("following")
        
        // MARK: - Get all subscriptions
        refToFollowings.observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if var userIds = value?.allKeys as? [String] {
                userIds.append(currentUserId!)   // adding current user for stip
                var countOfUsers = 0             // count of users posts already counted
                let countOfAllUsers = userIds.count
                var countofPosts = 0             // count of all posts for subscriptions already counted
                var countOfAllPosts = 0
                
                // MARK: - For each following user get list of posts
                for userId in userIds {
                    let refToUserPosts = FIRDatabase.database().reference(withPath: "MainDataBase/users").child(userId).child("posts")
                    
                    refToUserPosts.observeSingleEvent(of: .value, with: { snapshotOfPosts in // taking all posts cz every user has a list of posts, not objects
                        countOfUsers += 1
                        let valueOfPosts = snapshotOfPosts.value as? NSDictionary
                        if let postsIds = valueOfPosts?.allKeys as? [String] {
                            let slicedAndSortedPostsIds = self.getSortedCurrentPartOfArray(keys: postsIds, startFromFirst: true)
                            countOfAllPosts += slicedAndSortedPostsIds.count
                            
                            // MARK: - For each postId get full PostItem
                            for postId in slicedAndSortedPostsIds {
                                let refToPost = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost/" + postId)
                                refToPost.observeSingleEvent(of: .value, with: { snapshot in
                                    countofPosts += 1
                                    let spotPostItem = PostItem(snapshot: snapshot)
                                    let spotPostCellCache = PostItemCellCache(spotPost: spotPostItem, stripController: self) // stripController - we will update our tableview from another thread
                                    
                                    posts.append(spotPostItem)
                                    postsCache.append(spotPostCellCache)
                                    
                                    // check if we have ended all items -> sort, slice and append
                                    self.haveWeEnded(countOfUsers: countOfUsers, countOfAllUsers: countOfAllUsers,
                                                     countOfPosts: countofPosts, countOfAllPosts: countOfAllPosts,
                                                     posts: posts, postsCache: postsCache)
                                }) { (error) in
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    })
                }
            }
        })
    }
    
    private func getSortedCurrentPartOfArray(keys: [String], startFromFirst: Bool) -> ArraySlice<String> {
        let keysCount = keys.count
        var startIndex = startFromFirst ? 0 : self.countOfAlreadyLoadedPosts
        var endIndex = self.countOfPostsForGetting
        
        if endIndex > keysCount {
            endIndex = keysCount
        }
        
        if startIndex > keysCount {
            startIndex = keysCount
        }
        
        let cuttedSortered = (Array(keys).sorted(by: { $0 > $1 }))[startIndex..<endIndex]
        // 4 example if we have already loaded 10 posts,
        // we dont need to download them again
        
        return cuttedSortered
    }
    
    private func appendNewItems(posts: [PostItem], postsCache: [PostItemCellCache]) {
        self._posts.append(contentsOf: posts)
        self._postItemCellsCache.append(contentsOf: postsCache)
        // resort again. bcz can be problems cz threading
        self._posts = self._posts.sorted(by: { $0.key > $1.key })
        self._postItemCellsCache = self._postItemCellsCache.sorted(by: { $0.key > $1.key })
    }
    
    private func haveWeEnded(countOfUsers: Int, countOfAllUsers: Int,
                             countOfPosts: Int, countOfAllPosts: Int,
                             posts: [PostItem], postsCache: [PostItemCellCache]) {
        if countOfUsers == countOfAllUsers {     // if we have looked
            if countOfPosts == countOfAllPosts { // for everything we wanted
                let postsSorted               = posts.sorted(by: { $0.key > $1.key })
                let postsCacheSorted          = postsCache.sorted(by: { $0.key > $1.key })
                
                let endIndex: Int!
                if self.countOfPostsForGetting > countOfAllPosts { // for situatuons, when d > all count of posts.
                                                                   // Like when u r following only one user. And this user has only 1 post
                    endIndex = countOfAllPosts
                } else {
                    endIndex = self.countOfPostsForGetting
                }
                let postsSortedAndSliced      = Array(postsSorted[self.countOfAlreadyLoadedPosts..<endIndex])
                let postsCacheSortedAndSliced = Array(postsCacheSorted[self.countOfAlreadyLoadedPosts..<endIndex])
                
                self.appendNewItems(posts: postsSortedAndSliced, postsCache: postsCacheSortedAndSliced)
                self.countOfAlreadyLoadedPosts += self.dCountOfPostsForGetting
            }
        }
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
    
    func loadMoreBegin(loadMoreEnd:@escaping (Int) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.countOfPostsForGetting += self.dCountOfPostsForGetting
            self.loadPosts()
            sleep(2)
            
            DispatchQueue.main.async {
                loadMoreEnd(0)
            }
        }
    }
    
    // function for pull to refresh
    func refresh(sender: Any) {
        self._posts.removeAll()
        self._postItemCellsCache.removeAll()
        self.countOfAlreadyLoadedPosts = 0
        self.countOfPostsForGetting = self.dCountOfPostsForGetting // first pack
        // updating posts
        self.loadPosts()
        
        // ending refreshing
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    // ENDMARK: load posts region
    
    // Main table filling region
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self._posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostsCell", for: indexPath) as! PostsCell
        let row = indexPath.row
        
        if cell.userLikedOrDeletedLike { // when cell appears checking if like was tapped
            cell.userLikedOrDeletedLike = false
            updateCellLikesCache(objectId: cell.post.key) // if yes updating cache
        }
        
        let cellFromCache = _postItemCellsCache[row]
        cell.post                 = cellFromCache.post
        cell.userInfo             = cellFromCache.userInfo
        cell.userNickName.setTitle(cellFromCache.userNickName.text, for: .normal)
        cell.userNickName.tag     = row // for segue to send userId to ridersProfile
        cell.userNickName.addTarget(self, action: #selector(PostsStripController.nickNameTapped), for: .touchUpInside)
        cell.postDate.text        = cellFromCache.postDate.text
        cell.postTime.text        = cellFromCache.postTime.text
        cell.postDescription.text = cellFromCache.postDescription.text
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
        for postCellCache in _postItemCellsCache {
            if postCellCache.post.key == objectId {
                DispatchQueue.main.async {
                    postCellCache.changeLikeToDislikeAndViceVersa()
                }
            }
        }
    }
    
    func setMediaOnCellFromCacheOrDownload(cell: PostsCell, cacheKey: Int) {
        cell.spotPostMedia.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
        
        //Downloading and caching media
        if _posts[cacheKey].isPhoto {
            setImageOnCellFromCacheOrDownload(cell: cell, cacheKey: cacheKey)
        } else {
            setVideoOnCellFromCacheOrDownload(cell: cell, cacheKey: cacheKey)
        }
    }
    
    private var _mainPartOfMediaref: String!
    
    func setImageOnCellFromCacheOrDownload(cell: PostsCell, cacheKey: Int) {
        if self._postItemCellsCache[cacheKey].isCached {
            let url = _mainPartOfMediaref + self._posts[cacheKey].spotId + "/" + self._posts[cacheKey].key + "_resolution700x700.jpeg"
            let spotDetailsPhotoURL = FIRStorage.storage().reference(forURL: url)
            
            spotDetailsPhotoURL.downloadURL { (URL, error) in
                let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
                
                DispatchQueue.main.async {
                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                }
            }
        } else {
            // download thumbnail first
            let thumbnailUrl = _mainPartOfMediaref + self._posts[cacheKey].spotId + "/" + self._posts[cacheKey].key + "_resolution10x10.jpeg"
            let spotPostPhotoThumbnailURL = FIRStorage.storage().reference(forURL: thumbnailUrl)
            
            spotPostPhotoThumbnailURL.downloadURL { (URL, error) in
                if let error = error {
                    print("\(error)")
                } else {
                    let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                    let processor = BlurImageProcessor(blurRadius: 0.1)
                    imageViewForView.kf.setImage(with: URL, placeholder: nil, options: [.processor(processor)])
                    
                    DispatchQueue.main.async {
                        cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                    }
                    
                    self.downloadOriginalImage(cell: cell, cacheKey: cacheKey)
                }
            }
        }
    }
    
    private func downloadOriginalImage(cell: PostsCell, cacheKey: Int) {
        let url = _mainPartOfMediaref + self._posts[cacheKey].spotId + "/" + self._posts[cacheKey].key + "_resolution700x700.jpeg"
        let spotDetailsPhotoURL = FIRStorage.storage().reference(forURL: url)
        
        spotDetailsPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                imageViewForView.kf.indicatorType = .activity
                imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
                
                DispatchQueue.main.async {
                    self._postItemCellsCache[cacheKey].isCached = true
                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                }
            }
        }
    }
    
    func setVideoOnCellFromCacheOrDownload(cell: PostsCell, cacheKey: Int) {
        if (self._mediaCache.object(forKey: cacheKey) != nil) { // checking video existance in cache
            let cachedAsset = self._mediaCache.object(forKey: cacheKey) as? AVAsset
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
        let storage = FIRStorage.storage()
        let postKey = self._posts[cacheKey].key
        let url = _mainPartOfMediaref + self._posts[cacheKey].spotId + "/" + postKey + "_resolution10x10.jpeg"
        let spotVideoThumbnailURL = storage.reference(forURL: url)
        
        spotVideoThumbnailURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                // thumbnail!
                let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                let processor = BlurImageProcessor(blurRadius: 0.1)
                imageViewForView.kf.setImage(with: URL!, placeholder: nil, options: [.processor(processor)])
                imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                
                cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                
                self.downloadBigThumbnail(postKey: postKey, cacheKey: cacheKey, cell: cell)
            }
        }
    }
    
    private func downloadBigThumbnail(postKey: String, cacheKey: Int, cell: PostsCell) {
        let storage = FIRStorage.storage()
        let postKey = self._posts[cacheKey].key
        let url = _mainPartOfMediaref  + self._posts[cacheKey].spotId + "/" + postKey + "_resolution270x270.jpeg"
        let spotVideoThumbnailURL = storage.reference(forURL: url)
        
        spotVideoThumbnailURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                // thumbnail!
                let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                let processor = BlurImageProcessor(blurRadius: 0.1)
                imageViewForView.kf.setImage(with: URL!, placeholder: nil, options: [.processor(processor)])
                imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                
                cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                
                self.downloadVideo(postKey: postKey, cacheKey: cacheKey, cell: cell)
            }
        }
    }
    
    private func downloadVideo(postKey: String, cacheKey: Int, cell: PostsCell) {
        let storage = FIRStorage.storage()
        let url = _mainPartOfMediaref + self._posts[cacheKey].spotId + "/" + postKey + ".m4v"
        let spotVideoURL = storage.reference(forURL: url)
        
        spotVideoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                let assetForCache = AVAsset(url: URL!)
                self._mediaCache.setObject(assetForCache, forKey: cacheKey as NSCopying)
                cell.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
                let playerLayer = AVPlayerLayer(player: cell.player)
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                playerLayer.frame = cell.spotPostMedia.bounds
                
                cell.spotPostMedia.layer.addSublayer(playerLayer)
                
                cell.player.play()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: DZNEmptyDataSet for empty data tables
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Welcome"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Riders you are subscribed to do not have any publications. Go find some riders you want to follow to. Or post something yourself"
        let attrs = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return ImageManipulations.resize(image: UIImage(named: "no_photo.png")!, targetSize: CGSize(width: 300.0, height: 300.0))
    }
    
    // ENDMARK: DZNEmptyDataSet
    
    @IBAction func addNewPost(_ sender: Any) {
        self.performSegue(withIdentifier: "addNewPost", sender: self)
    }
    
    //go to riders profile
    func nickNameTapped(sender: UIButton!) {
        // check if going to current user
        if self._postItemCellsCache[sender.tag].userInfo.uid == FIRAuth.auth()?.currentUser?.uid {
            self.performSegue(withIdentifier: "ifChoosedCurrentUser", sender: self)
        } else {
            self.ridersInfoForSending = self._postItemCellsCache[sender.tag].userInfo
            self.performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
        }
    }
    
    var ridersInfoForSending: UserItem!
    
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
    }
}
