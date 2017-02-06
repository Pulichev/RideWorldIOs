//
//  spotPostsCell.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation

class SpotPostsCell: UITableViewCell
{
    var backendless: Backendless!
    
    var postId: String?
    @IBOutlet weak var spotPostPhoto: UIImageView!
    @IBOutlet weak var userNickName: UILabel!
    @IBOutlet weak var postDate: UILabel!
    @IBOutlet weak var postDescription: UITextView!
    @IBOutlet weak var isLikedPhoto: UIImageView!
    var postIsLiked: Bool!
    @IBOutlet weak var likesCount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //         Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        //          Configure the view for the selected state
    }
    
    func addDoubleTapGestureOnPostPhotos()
    {
        //adding method on spot main photo tap
        let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:)))
        tap.numberOfTapsRequired = 2
        spotPostPhoto.addGestureRecognizer(tap)
        spotPostPhoto.isUserInteractionEnabled = true
    }
    
    func postLiked(_ sender: Any)
    {
        let backendless = Backendless.sharedInstance()
        
        let defaults = UserDefaults.standard
        let userId = defaults.string(forKey: "userLoggedInObjectId")
        
        if(!self.postIsLiked)
        {
            let postLike = PostLike()
            postLike.postId = self.postId
            postLike.userId = userId
            
            backendless?.persistenceService.of(PostLike.ofClass()).save(postLike)
            
            self.postIsLiked = true
            self.isLikedPhoto.image = UIImage(named: "respectActive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! + 1)
        }
        else
        {
            //1) Finding postlike object of this cell
            //2) Delete this object from database
            let whereClause = "postId = '\(self.postId!)' AND userId = '\(userId!)'"
            let dataQuery = BackendlessDataQuery()
            dataQuery.whereClause = whereClause
            
            var error: Fault?
            let likesList = backendless?.data.of(PostLike.ofClass()).find(dataQuery, fault: &error) //Finding
            
            backendless?.persistenceService.of(PostLike.ofClass()).remove(likesList?.data[0]) //Deleting
            
            self.postIsLiked = false
            self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
            let countOfLikesInt = Int(self.likesCount.text!)
            self.likesCount.text = String(countOfLikesInt! - 1)
        }
    }
}
