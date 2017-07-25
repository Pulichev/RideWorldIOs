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
            self.backgroundColor = #colorLiteral(red: 0.1569, green: 0.1569, blue: 0.1569, alpha: 1) /* #282828 */
         } else {
            self.transform = .identity
            self.backgroundColor = #colorLiteral(red: 0.3804, green: 0.3804, blue: 0.3804, alpha: 1) /* #616161 */
         }
      })
      
      return super.beginTracking(touch, with: event)
   }
   
   override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
   }
}
