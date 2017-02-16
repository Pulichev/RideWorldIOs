//
//  RidersProfileController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 15.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class RidersProfileController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var ridersInfo: Users!
    
    var backendless: Backendless!
    
    @IBOutlet var userNameAndSename: UILabel!
    @IBOutlet var userNickName: UILabel!
    @IBOutlet var recpectedTimes: UILabel!
    @IBOutlet var ridersBio: UITextView!
    @IBOutlet var ridersProfilePhoto: UIImageView!
    
    @IBOutlet var riderProfileCollection: UICollectionView!
    var spotsPostsImages = [UIImageView]()
    
    override func viewDidLoad() {
        self.backendless = Backendless.sharedInstance()
        
        initializeUserTextInfo() //async loading user
        initializeUserPhoto()
        initializeUserPostsPhotos()
        
        super.viewDidLoad()
    }
    
    func initializeUserTextInfo() {
        self.userNickName.text = ridersInfo.name
        self.ridersBio.text = ridersInfo.userBioDescription
        self.userNameAndSename.text = ridersInfo.userNameAndSename
        
        placeBorderOnTextView()
        
        //Need to optimize this alghoritm
        DispatchQueue.global().async {
            let whereClause1 = "userId = '\(self.ridersInfo.objectId!)'"
            let dataQuery1 = BackendlessDataQuery()
            dataQuery1.whereClause = whereClause1
            
            let ridersPosts = self.backendless.data.of(SpotPost.ofClass()).find(dataQuery1)
            
            var ridersLikesCount = 0
            for riderPost in (ridersPosts?.data as! [SpotPost]) {
                let whereClause2 = "postId = '\(riderPost.objectId!)'"
                let dataQuery2 = BackendlessDataQuery()
                dataQuery2.whereClause = whereClause2
                
                let ridersLikes = self.backendless.data.of(PostLike.ofClass()).find(dataQuery2)
                ridersLikesCount += (ridersLikes?.data.count)!
            }
            
            DispatchQueue.main.async {
                self.recpectedTimes.text = String(ridersLikesCount)
            }
        }
    }
    
    func placeBorderOnTextView() {
        ridersBio.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        ridersBio.layer.borderWidth = 1.0
        ridersBio.layer.cornerRadius = 5
    }
    
    func initializeUserPhoto() {
        DispatchQueue.global(qos: .userInteractive).async {
            let userPhotoURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/userProfilePhotos/" + (self.ridersInfo.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
            let userPhotoData = NSData(contentsOf: URL(string: userPhotoURL)!)
            let userPhoto = UIImage(data: userPhotoData as! Data)!
            
            DispatchQueue.main.async {
                self.ridersProfilePhoto.image = userPhoto
                self.ridersProfilePhoto.layer.cornerRadius = self.ridersProfilePhoto.frame.size.height / 6
            }
        }
    }
    
    func initializeUserPostsPhotos() {
        DispatchQueue.global(qos: .userInteractive).async {
            let whereClause = "userId = '\(self.ridersInfo.objectId!)'"
            let dataQuery = BackendlessDataQuery()
            dataQuery.whereClause = whereClause
            
            var error: Fault?
            
            let spotPostsList = self.backendless.data.of(SpotPost.ofClass()).find(dataQuery, fault: &error)
            
            for spotPost in (spotPostsList?.data as! [SpotPost]) {
                var photo = UIImage()
                var mediaURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/"
                
                if spotPost.isPhoto {
                    mediaURL += "SpotPostPhotos/" + (spotPost.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
                    let photoData = NSData(contentsOf: URL(string: mediaURL)!)
                    photo = UIImage(data: photoData as! Data)!
                } else {
                    mediaURL += "SpotPostVideos/" + (spotPost.objectId!).replacingOccurrences(of: "-", with: "") + ".m4v"
                    let filePath = URL(string: mediaURL)
                    
                    do {
                        let asset = AVURLAsset(url: filePath! , options: nil)
                        let imgGenerator = AVAssetImageGenerator(asset: asset)
                        imgGenerator.appliesPreferredTrackTransform = true
                        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
                        photo = UIImage(cgImage: cgImage)
                    } catch let error {
                        print("*** Error generating thumbnail: \(error.localizedDescription)")
                    }
                }
                
                let photoView = UIImageView(image: photo)
                
                DispatchQueue.main.async {
                    self.spotsPostsImages.append(photoView)
                    self.riderProfileCollection.reloadData()
                }
            }
        }
    }
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.spotsPostsImages.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RidersProfileCollectionViewCell", for: indexPath as IndexPath) as! RidersProfileCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.postPicture.image = self.spotsPostsImages[indexPath.row].image
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        print("You selected cell #\(indexPath.item)!")
    }
}
