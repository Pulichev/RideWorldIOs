//
//  SpotDetailsController.swift
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
import SDWebImage

class SpotDetailsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var spotDetailsItem: SpotDetailsItem!
    
    private var spotPosts = [SpotPostItem]()
    private var spotPostItemCellsCache = [SpotPostItemCellCache]()
    
    private var mediaCache = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self._mainPartOfMediaref = "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + self.spotDetailsItem.key + "/" // will use it in media download
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.loadSpotPosts()
        }
    }
    
    private func loadSpotPosts() {
        //getting a list of keys of spot posts from spotdetails
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotdetails/" + self.spotDetailsItem.key + "/posts")
        
        ref.queryOrderedByValue().observe(.value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if let keys = value?.allKeys as? [String] {
                for key in keys {
                    let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost/" + key)
                    
                    ref.observeSingleEvent(of: .value, with: { snapshot in
                        let spotPostItem = SpotPostItem(snapshot: snapshot)
                        self.spotPosts.append(spotPostItem)
                        
                        let newSpotPostCellCache = SpotPostItemCellCache(spotPost: spotPostItem)
                        newSpotPostCellCache.userLikedThisPost()
                        self.spotPostItemCellsCache.append(newSpotPostCellCache)
                        
                        self.tableView.reloadData()
                    }) { (error) in
                        print(error.localizedDescription)
                    }
                }
            }
        })
    }
    
    //First add must have info. Text info.
    private func loadSpotPostCellsTextInfo() {
        var i = 0
        
        DispatchQueue.main.async {
            for post in self.spotPosts {
                let newSpotPostCellCache = SpotPostItemCellCache(spotPost: post)
                
                self.spotPostItemCellsCache.append(newSpotPostCellCache)
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
            updateCellLikesCache(objectId: cell.post.key) //if yes updating cache
        }
        
        let cellFromCache = spotPostItemCellsCache[row]
        cell.post = cellFromCache.post
        cell.userInfo = cellFromCache.userInfo
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
    
    private func updateCellLikesCache(objectId: String) {
        for postCellCache in spotPostItemCellsCache {
            if postCellCache.post.key == objectId {
                DispatchQueue.main.async {
                    postCellCache.changeLikeToDislikeAndViceVersa()
                }
            }
        }
    }
    
    func setMediaOnCellFromCacheOrDownload(cell: SpotPostsCell, cacheKey: Int) {
        cell.spotPostMedia.layer.sublayers?.forEach { $0.removeFromSuperlayer() } //deleting old data from view (photo or video)
        
        //Downloading and caching media
        if spotPosts[cacheKey].isPhoto {
            setImageOnCellFromCacheOrDownload(cell: cell, cacheKey: cacheKey)
        } else {
            setVideoOnCellFromCacheOrDownload(cell: cell, cacheKey: cacheKey)
        }
    }
    
    private var _mainPartOfMediaref: String!
    
    func setImageOnCellFromCacheOrDownload(cell: SpotPostsCell, cacheKey: Int) {
        if self.spotPostItemCellsCache[cacheKey].isCached {
            let url = _mainPartOfMediaref + self.spotPosts[cacheKey].key + "_resolution700x700.jpeg"
            let spotDetailsPhotoURL = FIRStorage.storage().reference(forURL: url)
            
            spotDetailsPhotoURL.downloadURL { (URL, error) in
                let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
//                imageViewForView.sd_setImage(with: URL)
                
                DispatchQueue.main.async {
                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                }
            }
        } else {
            // download thumbnail first
            let thumbnailUrl = _mainPartOfMediaref + self.spotPosts[cacheKey].key + "_resolution10x10.jpeg"
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
    
    private func downloadOriginalImage(cell: SpotPostsCell, cacheKey: Int) {
        let url = _mainPartOfMediaref + self.spotPosts[cacheKey].key + "_resolution700x700.jpeg"
        let spotDetailsPhotoURL = FIRStorage.storage().reference(forURL: url)
        
        spotDetailsPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                imageViewForView.kf.indicatorType = .activity
                imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
//                imageViewForView.sd_setImage(with: URL)
                
                DispatchQueue.main.async {
                    self.spotPostItemCellsCache[cacheKey].isCached = true
                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                }
            }
        }
    }
    
    func setVideoOnCellFromCacheOrDownload(cell: SpotPostsCell, cacheKey: Int) {
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
    
    private func downloadThumbnail(cacheKey: Int, cell: SpotPostsCell) {
        let storage = FIRStorage.storage()
        let postKey = self.spotPosts[cacheKey].key
        let url = _mainPartOfMediaref + postKey + "_resolution10x10.jpeg"
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
    
    private func downloadBigThumbnail(postKey: String, cacheKey: Int, cell: SpotPostsCell) {
        let storage = FIRStorage.storage()
        let postKey = self.spotPosts[cacheKey].key
        let url = _mainPartOfMediaref + postKey + "_resolution270x270.jpeg"
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
    
    private func downloadVideo(postKey: String, cacheKey: Int, cell: SpotPostsCell) {
        let storage = FIRStorage.storage()
        let url = _mainPartOfMediaref + postKey + ".m4v"
        let spotVideoURL = storage.reference(forURL: url)
        
        spotVideoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                let assetForCache = AVAsset(url: URL!)
                self.mediaCache.setObject(assetForCache, forKey: cacheKey as NSCopying)
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
    
    @IBAction func addNewPost(_ sender: Any) {
        self.performSegue(withIdentifier: "addNewPost", sender: self)
    }
    
    //go to riders profile
    func nickNameTapped(sender: UIButton!) {
        // check if going to current user
        if self.spotPostItemCellsCache[sender.tag].userInfo.uid == FIRAuth.auth()?.currentUser?.uid {
            self.performSegue(withIdentifier: "ifChoosedCurrentUser", sender: self)
        } else {
            self.ridersInfoForSending = self.spotPostItemCellsCache[sender.tag].userInfo
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
