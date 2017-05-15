//
//  CommentFeedBackCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import ActiveLabel

class CommentAndLikeFBCell: UITableViewCell { // FB = feedback
   var userId: String! { // maybe userItem
      didSet {
         User.getItemById(for: userId,
                          completion: { user in
                           self.userPhoto?.kf.setImage(with: URL(
                              string: user.photo90ref!))
                           self.userLoginButton.setTitle(user.login,
                                                         for: .normal)
         })
      }
   }
   
   var postId: String! { // maybe postItem
      didSet {
         Post.getItemById(for: postId,
                          completion: { post in
                           self.postPhoto?.kf.setImage(with: URL(
                              string: (post?.mediaRef270)!))
         })
      }
   }
   
   // MARK: - @IBOutlets
   // media
   @IBOutlet weak var userPhoto: RoundedImageView!
   @IBOutlet weak var postPhoto: UIImageView!
   // text info
   @IBOutlet weak var userLoginButton: UIButton!
   @IBOutlet weak var desc: ActiveLabel!
   @IBOutlet weak var dateTime: UILabel!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      // Initialization code
   }
   
   override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
      
      // Configure the view for the selected state
   }
   
   @IBAction func loginButtonTapped(_ sender: UIButton) {
      
   }
}
