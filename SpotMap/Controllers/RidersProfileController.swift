//
//  RidersProfileController.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 15.02.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation
import UIKit

class RidersProfileController: UIViewController {
    var ridersInfo: Users!
    
    var backendless: Backendless!
    
    @IBOutlet var userNameAndSename: UILabel!
    @IBOutlet var userNickName: UILabel!
    @IBOutlet var recpectedTimes: UILabel!
    @IBOutlet var ridersBio: UITextView!
    @IBOutlet var ridersProfilePhoto: UIImageView!
    
    @IBOutlet var riderProfileCollection: UICollectionView!
    
    override func viewDidLoad() {
        self.backendless = Backendless.sharedInstance()
        
        initializeUserTextInfo() //async loading user
        initializeUserPhoto()
        
        super.viewDidLoad()
    }
    
    func initializeUserTextInfo() {
        self.userNickName.text = ridersInfo.name
        self.ridersBio.text = ridersInfo.userBioDescription
        self.userNameAndSename.text = ridersInfo.userNameAndSename
        
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
}
