//
//  SpotAnnotationViewCallout.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 27.09.2017.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Kingfisher

class SpotAnnotationViewCallout: View {
   
   @IBOutlet weak var spotPhoto: UIImageView!
   @IBOutlet weak var goToInfoButton: UIButtonX!
   @IBOutlet weak var goToPostsButton: UIButtonX!
   
   func addPhoto(spot: SpotItem) {
      spotPhoto.kf.setImage(with: URL(string: spot.mainPhotoRef))
      
      // some settings for image
      spotPhoto.layer.cornerRadius = spotPhoto.frame.size.height / 10
      spotPhoto.layer.masksToBounds = true
      spotPhoto.contentMode = UIViewContentMode.scaleAspectFill
   }
}

