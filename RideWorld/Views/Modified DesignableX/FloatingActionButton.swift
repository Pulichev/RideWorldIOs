//
//  FloatingActionButton.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 25.07.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit

class FloatingActionButton: UIButtonX {
  
  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    
    UIView.animate(withDuration: 0.3, animations: {
      if self.transform == .identity {
        self.transform = CGAffineTransform(rotationAngle: 0.25 * .pi)
        self.backgroundColor = UIColor(white: 1.0, alpha: 0.0)
        self.borderWidth = 0.0
        self.tintColor = UIColor.myBlack()
      } else {
        self.transform = .identity
        self.backgroundColor = UIColor.myBlack()
        self.borderWidth = 2.0
        self.tintColor = UIColor.white
      }
    })
    
    return super.beginTracking(touch, with: event)
  }
  
  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    return super.endTracking(touch, with: event)
  }
}
