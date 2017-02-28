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
    @IBOutlet var recpectedTimes: UILabel!
    @IBOutlet var ridersBio: UITextView!
    @IBOutlet var ridersProfilePhoto: UIImageView!
    
    @IBOutlet var riderProfileCollection: UICollectionView!
    var spotPosts = [SpotPost]()
    var spotsPostsImages = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.backendless = Backendless.sharedInstance()
            
            self.initializeUserTextInfo() //async loading user
            self.initializeUserPhoto()
            self.initializeUserPostsPhotos()
        }
    }
    
    func initializeUserTextInfo() {
        self.ridersBio.text = ridersInfo.userBioDescription
        self.userNameAndSename.text = ridersInfo.userNameAndSename
        
        placeBorderOnTextView()
        
        DispatchQueue.global().async {
            let whereClause1 = "post.ownerId = '\(self.ridersInfo.objectId!)'"
            let dataQuery1 = BackendlessDataQuery()
            dataQuery1.whereClause = whereClause1
            
            let usersLikes = self.backendless.data.of(PostLike.ofClass()).find(dataQuery1)
            
            DispatchQueue.main.async {
                self.recpectedTimes.text = String(describing: (usersLikes?.data.count)!)
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
                self.ridersProfilePhoto.layer.cornerRadius = self.ridersProfilePhoto.frame.size.height / 2
            }
        }
    }
    
    func initializeUserPostsPhotos() {
        DispatchQueue.global(qos: .userInteractive).async {
            let whereClause = "user.objectId = '\(self.ridersInfo.objectId!)'"
            let dataQuery = BackendlessDataQuery()
            dataQuery.whereClause = whereClause
            
            var error: Fault?
            
            let spotPostsList = self.backendless.data.of(SpotPost.ofClass()).find(dataQuery, fault: &error)
            self.spotPosts = spotPostsList?.data as! [SpotPost]
            
            for spotPost in self.spotPosts {
                var photo = UIImage()
                var mediaURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/"
                
                mediaURL += "spotPostMediaThumbnails/" + (spotPost.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
                let photoData = NSData(contentsOf: URL(string: mediaURL)!)
                photo = UIImage(data: photoData as! Data)!
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
    
    var selectedCellId: Int!
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        self.selectedCellId = indexPath.item
        self.performSegue(withIdentifier: "goToPostInfo", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPostInfo" {
            let newPostInfoController = (segue.destination as! PostInfoViewController)
            newPostInfoController.postInfo = spotPosts[selectedCellId]
            newPostInfoController.user = ridersInfo
        }
    }
}
