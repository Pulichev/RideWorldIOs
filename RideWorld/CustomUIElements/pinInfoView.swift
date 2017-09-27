//
//  pinInfoView.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 23.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class PinInfoView: UIView {
   private let width = 200
   private let height = 200
   
   var goToInfoButton: UIButtonX!
   var goToPostsButton: UIButtonX!
   var title: UILabelX!
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      
      let views = ["infoView": self]
      self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[infoView(200)]",
                                                         options: [], metrics: nil, views: views))
      self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[infoView(200)]",
                                                         options: [], metrics: nil, views: views))
      
      initButtons()
      
      self.addSubview(goToPostsButton)
      self.addSubview(goToInfoButton)
   }
   
   required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }
   
   private func initButtons() {
      goToInfoButton = UIButtonX(frame: CGRect(x: 0, y: height - 35, width: width / 2 - 5, height: 35))
      goToInfoButton.setTitle(NSLocalizedString("Info", comment: ""), for: .normal)
      goToInfoButton.setTitleColor(UIColor.myBlack(), for: .normal)
      goToInfoButton.backgroundColor = UIColor.white
      goToInfoButton.cornerRadius = 10
      goToInfoButton.borderWidth = 1
      goToInfoButton.borderColor = UIColor.myBlack()
      
      goToPostsButton = UIButtonX(frame: CGRect(x: width / 2 + 5, y: height - 35, width: width / 2, height: 35))
      goToPostsButton.setTitle(NSLocalizedString("Posts", comment: ""), for: .normal)
      goToPostsButton.setTitleColor(UIColor.myBlack(), for: .normal)
      goToPostsButton.backgroundColor = UIColor.white
      goToPostsButton.cornerRadius = 10
      goToPostsButton.borderWidth = 1
      goToPostsButton.borderColor = UIColor.myBlack()
   }
   
   func addPhoto(spot: SpotItem) {
      let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height - 40))
      
      imageView.kf.setImage(with: URL(string: spot.mainPhotoRef))
      
      imageView.layer.cornerRadius = imageView.frame.size.height / 10
      imageView.layer.masksToBounds = true
      imageView.contentMode = UIViewContentMode.scaleAspectFill
      
      self.addSubview(imageView)
   }
}
