//
//  FollowerFBCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 11.05.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class FollowerFBCell: UITableViewCell { // FB = feedback
   var userId: String! // maybe userItem
   
   // MARK: - @IBOutlets
   // media
   @IBOutlet weak var userPhoto: RoundedImageView!
   // text info
   @IBOutlet weak var loginButton: UIButton!
   @IBOutlet weak var desc: UILabel!
   @IBOutlet weak var followButton: UIButton!
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
   
   @IBAction func followButtonTapped(_ sender: UIButton) {
      
   }
}
