//
//  SpotFollowingCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 22.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class SpotFollowingCell: UITableViewCell {
   
   @IBOutlet weak var spotName: UILabel!
   @IBOutlet weak var spotImage: RoundedImageView!
   @IBOutlet weak var button: UIButton!
   
   var spot: SpotItem! {
      didSet {
         spotName.text = spot.name
         initialiseSpotPhoto()
         initialiseFollowButton()
      }
   }
   
   func initialiseSpotPhoto() {
      spotImage.image = UIImage(named: "grayRec.png")
      
      if spot.mainPhotoRef != nil {
         spotImage.kf.setImage(with: URL(string: spot.mainPhotoRef!)) // Using kf for caching images.
      } else {
         spotImage.setImage(string: spot.name, color: nil, circular: true,
                            textAttributes: [NSFontAttributeName: UIFont(name: "Roboto-Light", size: 20)])
      }
   }
   
   func initialiseFollowButton() {
      Spot.isCurrentUserFollowingSpot(with: spot.key) { isFollowing in
         if isFollowing {
            self.button.setTitle(NSLocalizedString("Following", comment: ""), for: .normal)
         } else {
            self.button.setTitle(NSLocalizedString("Follow", comment: ""), for: .normal)
         }
         
         self.button.isEnabled = true
      }
   }
   
   @IBAction func followButtonTapped(_ sender: Any) {
      if button.currentTitle == NSLocalizedString("Follow", comment: "") {
         Spot.addFollowingToSpot(with: spot.key)
      } else {
         Spot.removeFollowingToSpot(with: spot.key)
      }
      
      swapFollowButtonTittle()
   }
   
   private func swapFollowButtonTittle() {
      if button.currentTitle == NSLocalizedString("Follow", comment: "") {
         button.setTitle(NSLocalizedString("Following", comment: ""), for: .normal)
      } else {
         button.setTitle(NSLocalizedString("Follow", comment: ""), for: .normal)
      }
   }
}
