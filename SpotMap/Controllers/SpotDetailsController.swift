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

class SpotDetailsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var spotDetailsItem: SpotDetailsItem!
    
    var spotPosts = [SpotPostItem]()
    var spotPostItemCellsCache = [SpotPostItemCellCache]()
    
    var mediaCache = NSMutableDictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        //DispatchQueue.global(qos: .userInitiated).async {
        self.loadSpotPosts()
        //}
    }
    
    func loadSpotPosts() {
        //getting a list of keys of spot posts from spotdetails
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotdetails/" + self.spotDetailsItem.key + "/posts")
        
        ref.queryOrderedByValue().observe(.value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            let keys = value?.allKeys as! [String]
            
            for key in keys {
                let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotpost/" + key)
                
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    let spotPostItem = SpotPostItem(snapshot: snapshot)
                    self.spotPosts.append(spotPostItem)
                    let newSpotPostCellCache = SpotPostItemCellCache(spotPost: spotPostItem)
                    self.spotPostItemCellsCache.append(newSpotPostCellCache)
                    self.tableView.reloadData()
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
            
            //self.loadSpotPostCellsTextInfo() //when posts loaded we can add text info on cells
        })
    }
    
    //First add must have info. Text info.
    func loadSpotPostCellsTextInfo() {
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
        let storage = FIRStorage.storage()
        let url = "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + self.spotDetailsItem.key + "/" + self.spotPosts[cacheKey].key + ".jpeg"
        let spotDetailsPhotoURL = storage.reference(forURL: url)
        
        spotDetailsPhotoURL.downloadURL { (URL, error) in
            if let error = error {
                print("\(error)")
            } else {
                let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                imageViewForView.kf.setImage(with: URL) //Using kf for caching images.
                DispatchQueue.main.async {
                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                }
            }
        }
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
            let storage = FIRStorage.storage()
            let postKey = self.spotPosts[cacheKey].key
            let url = "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + self.spotDetailsItem.key + "/" + postKey + "_thumbnail.jpeg"
            let spotVideoThumbnailURL = storage.reference(forURL: url)
            
            spotVideoThumbnailURL.downloadURL { (URL, error) in
                if let error = error {
                    print("\(error)")
                } else {
                    let data = NSData(contentsOf: URL!)
                    let thumbnail: UIImage = UIImage(data: data as! Data)!
                    
                    // thumbnail!
                    let imageViewForView = UIImageView(frame: cell.spotPostMedia.frame)
                    imageViewForView.image = thumbnail
                    imageViewForView.layer.contentsGravity = kCAGravityResizeAspectFill
                    cell.spotPostMedia.layer.addSublayer(imageViewForView.layer)
                    
                    self.downloadVideo(postKey: postKey, cacheKey: cacheKey, cell: cell)
                }
            }
        }
    }
    
    func downloadVideo(postKey: String, cacheKey: Int, cell: SpotPostsCell) {
        let storage = FIRStorage.storage()
        let url = "gs://spotmap-e3116.appspot.com/media/spotPostMedia/" + self.spotDetailsItem.key + "/" + postKey + ".m4v"
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
    
    func updateCellLikesCache(objectId: String) {
        for postCellCache in spotPostItemCellsCache {
            if postCellCache.post.key == objectId {
                DispatchQueue.main.async {
                    postCellCache.changeLikeToDislikeAndViceVersa()
                }
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
        //        self.ridersInfoForSending = self.spotPostsCellsCache[sender.tag].userInfo
        //        self.performSegue(withIdentifier: "openRidersProfileFromSpotDetails", sender: self)
    }
    
    var ridersInfoForSending: Users!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //        if segue.identifier == "addNewPost" {
        //            //let nav = segue.destination as! UINavigationController
        //            let newPostController = segue.destination	 as! NewPostController
        //            newPostController.spotDetails = self.spotDetails
        //        }
        //        if segue.identifier == "openRidersProfileFromSpotDetails" {
        //            let newRidersProfileController = (segue.destination as! RidersProfileController)
        //            newRidersProfileController.ridersInfo = ridersInfoForSending
        //            newRidersProfileController.title = ridersInfoForSending.name
        //        }
    }
}
