//
//  SpotDetailsController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation

class SpotDetailsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var backendless: Backendless!
    
    @IBOutlet weak var tableView: UITableView!
    
    var spotDetails: SpotDetails!
    
    var spotPosts = [SpotPost]()
    var spotPostsCellsCache = [SpotPostsCellCache]()
    
    var mediaCache = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.backendless = Backendless.sharedInstance()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadSpotPosts()
        }
    }
    
    func loadSpotPosts() {
        let whereClause = "spotId.objectId = '\(spotDetails.objectId!)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        var error: Fault?
        
        let spotPostsList = self.backendless.data.of(SpotPost.ofClass()).find(dataQuery, fault: &error)
        
        if error == nil {
            self.spotPosts = spotPostsList?.data as! [SpotPost]
            self.loadSpotPostCellsTextInfo() //when posts loaded we can add text info on cells
        } else {
            print("Server reported an error: \(error?.message)")
        }
    }
    
    //First add must have info. Text info.
    func loadSpotPostCellsTextInfo() {
        var i = 0
        
        DispatchQueue.main.async {
            for spot in self.spotPosts {
                let newSpotPostCellCache = SpotPostsCellCache()
                
                newSpotPostCellCache.userInfo = spot.userId! //getting userinfo
                newSpotPostCellCache.postId = spot.objectId!
                newSpotPostCellCache.userNickName.text = newSpotPostCellCache.userInfo.name
                
                let sourceDate = String(describing: spot.created!)
                //formatting date to yyyy-mm-dd
                let finalDate = sourceDate[sourceDate.startIndex..<sourceDate.index(sourceDate.startIndex, offsetBy: 10)]
                newSpotPostCellCache.postDate.text = finalDate
                newSpotPostCellCache.postDescription.text = spot.postDescription
                newSpotPostCellCache.isPhoto = spot.isPhoto
                newSpotPostCellCache.userLikedThisPost()
                newSpotPostCellCache.countPostLikes()
                
                self.spotPostsCellsCache.append(newSpotPostCellCache)
                self.tableView.reloadData()

                i += 1
            }
        }
    }
    
    //Main table filling region
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.spotPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpotPostsCell", for: indexPath) as! SpotPostsCell
        let row = indexPath.row
        
        if cell.userLikedOrDeletedLike { //when cell appears checking if like was tapped
            cell.userLikedOrDeletedLike = false
            updateCellLikesCache(objectId: cell.postId!) //if yes updating cache
        }
        
        let cellFromCache = spotPostsCellsCache[row]
        cell.postId = cellFromCache.postId
        cell.userNickName.setTitle(cellFromCache.userNickName.text, for: .normal)
        cell.userNickName.tag = row //for segue to send userId to ridersProfile
        cell.userNickName.addTarget(self, action: #selector(SpotDetailsController.nickNameTapped), for: .touchUpInside)
        cell.postDate.text = cellFromCache.postDate.text
        cell.postDescription.text = cellFromCache.postDescription.text
        cell.likesCount.text = String(cellFromCache.likesCount)
        cell.postIsLiked = cellFromCache.postIsLiked
        cell.isPhoto = cellFromCache.isPhoto
        cell.isLikedPhoto.image = cellFromCache.isLikedPhoto.image
        setMediaOnCellFromCacheOrDownload(cell: cell, cacheKey: row) //cell.spotPostPhoto setting async
        cell.addDoubleTapGestureOnPostPhotos()
        
        return cell
    }
    
    //TODO: Make code review
    func setMediaOnCellFromCacheOrDownload(cell: SpotPostsCell, cacheKey: Int) {
        cell.spotPostMedia.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
        
        //Downloading and caching media
        if spotPosts[cacheKey].isPhoto {
            setImageOnCellFromCacheOrDownload(cell: cell, cacheKey: cacheKey)
        } else {
            setVideoOnCellFromCacheOrDownload(cell: cell, cacheKey: cacheKey)
        }
    }
    
    func setImageOnCellFromCacheOrDownload(cell: SpotPostsCell, cacheKey: Int) {
        let postPhotoURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/SpotPostPhotos/" + (spotPosts[cacheKey].objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
        
        if (self.mediaCache.object(forKey: cacheKey) != nil) {
            let imageFromCache = self.mediaCache.object(forKey: cacheKey as NSCopying) as? UIImage
            let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
            imageViewForView.image = imageFromCache
            imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
            cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
        } else {
            DispatchQueue.global(qos: .userInteractive).async(execute: {
                if let url = URL(string: postPhotoURL) {
                    if let data = NSData(contentsOf: url) {
                        let imageFromCache: UIImage = UIImage(data: data as Data)!
                        self.mediaCache.setObject(imageFromCache, forKey: cacheKey as NSCopying)
                        
                        DispatchQueue.main.async(execute: {
                            let imageFromCache = self.mediaCache.object(forKey: cacheKey as NSCopying) as? UIImage
                            let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                            imageViewForView.image = imageFromCache
                            imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                            cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                        })
                    }
                }
            })
        } //end downloading and caching images
    }
    
    func setVideoOnCellFromCacheOrDownload(cell: SpotPostsCell, cacheKey: Int) {
        if (self.mediaCache.object(forKey: cacheKey) != nil) {
            let cachedAsset = self.mediaCache.object(forKey: cacheKey) as? AVAsset
            cell.player = AVPlayer(playerItem: AVPlayerItem(asset: cachedAsset!))
            let playerLayer = AVPlayerLayer(player: (cell.player))
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            playerLayer.frame = cell.spotPostMedia.bounds
            cell.spotPostMedia.layer.addSublayer(playerLayer)
            
            cell.player.play()
        } else {
            let postVideoURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/SpotPostVideos/" + (spotPosts[cacheKey].objectId!).replacingOccurrences(of: "-", with: "") + ".m4v"
            if let url = URL(string: postVideoURL) {
                
                DispatchQueue.global(qos: .userInteractive).async(execute: {
                    self.makeThumbnailFirst(postId: self.spotPosts[cacheKey].objectId!, cell: cell)
                    
                    let assetForCache = AVAsset(url: url)
                    self.mediaCache.setObject(assetForCache, forKey: cacheKey as NSCopying)
                    
                    DispatchQueue.main.async(execute: {
                        cell.player = AVPlayer(playerItem: AVPlayerItem(asset: assetForCache))
                        let playerLayer = AVPlayerLayer(player: cell.player)
                        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                        playerLayer.frame = cell.spotPostMedia.bounds
                        
                        cell.spotPostMedia.layer.addSublayer(playerLayer)
                        
                        cell.player.play()
                    })
                })
            }
        }
    }
    
    func makeThumbnailFirst(postId: String, cell: SpotPostsCell) {
        let thumbnailUrl = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/spotPostMediaThumbnails/" + postId.replacingOccurrences(of: "-", with: "") + ".jpeg"
        
        let url = URL(string: thumbnailUrl)
        let data = NSData(contentsOf: url!)
        let thumbnail: UIImage = UIImage(data: data as! Data)!
        
        DispatchQueue.main.async {
            // thumbnail
            let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
            imageViewForView.image = thumbnail
            imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
            cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let customCell = cell as! SpotPostsCell
        if (!customCell.isPhoto && customCell.player != nil) {
            if (customCell.player.rate != 0 && (customCell.player.error == nil)) {
                // player is playing
                customCell.player.pause()
                customCell.player = nil
            }
        }
    }
    
    func updateCellLikesCache(objectId: String) {
        for postCellCache in spotPostsCellsCache {
            if postCellCache.postId == objectId {
                DispatchQueue.main.async {
                    postCellCache.changeLikeToDislikeAndViceVersa()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func getUserInfo(userId: String?) -> Users {
        let user = self.backendless.userService.find(byId: userId!)
        //        print("\(user)")
        let rider = Users()
        rider.objectId = userId!
        rider.name = String(describing: (user?.getProperty("name"))!)
        rider.email = String(describing: (user?.getProperty("email"))!)
        rider.userNameAndSename = String(describing: (user?.getProperty("userNameAndSename"))!)
        rider.userBioDescription = String(describing: (user?.getProperty("userBioDescription"))!)
        return rider
    }
    //ENDTABLE filling region
    
    @IBAction func addNewPost(_ sender: Any) {
        self.performSegue(withIdentifier: "addNewPost", sender: self)
    }
    
    //go to riders profile
    func nickNameTapped(sender: UIButton!) {
        self.ridersInfoForSending = self.spotPostsCellsCache[sender.tag].userInfo
        self.performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
    }
    
    var ridersInfoForSending: Users!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addNewPost" {
            //let nav = segue.destination as! UINavigationController
            let newPostController = segue.destination	 as! NewPostController
            newPostController.spotDetails = self.spotDetails
        }
        if segue.identifier == "openRidersProfileFromSpotDetails" {
            let newRidersProfileController = (segue.destination as! RidersProfileController)
            newRidersProfileController.ridersInfo = ridersInfoForSending
            newRidersProfileController.title = ridersInfoForSending.name
        }
    }
}
