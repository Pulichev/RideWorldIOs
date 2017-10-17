//
//  RoundedImageView.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 18.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import FirebaseDatabase

@IBDesignable
class RoundedImageView: UIImageView {
  
  override init(image: UIImage?) {
    super.init(image: image)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func layoutSubviews() {
    self.layer.cornerRadius = self.frame.size.height / 2
    self.clipsToBounds = true
  }
}
