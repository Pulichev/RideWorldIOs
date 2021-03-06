//
//  CircularProgress.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 23.06.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import KYCircularProgress

/// For adding circular progress bar for UIImageView downloading etc.
class CircularProgress {
  
  var view: KYCircularProgress
  
  init(on frame: CGRect) {
    view = KYCircularProgress(frame: frame,
                              showGuide: true)
    
    let center = CGPoint(x: frame.width / 2,
                         y: frame.height / 2)
    
    view.path = UIBezierPath(arcCenter: center,
                             radius: CGFloat(50.0),
                             startAngle: CGFloat(0.0),
                             endAngle: CGFloat(2 * Double.pi),
                             clockwise: true)
    
    view.colors = [UIColor(rgba: 0xA6E39DAA),
                   UIColor(rgba: 0xAEC1E3AA),
                   UIColor(rgba: 0xAEC1E3AA),
                   UIColor(rgba: 0xF3C0ABAA)]
    
    view.guideColor = UIColor(red: 0.1,
                              green: 0.1,
                              blue: 0.1,
                              alpha: 0.4)
  }
}
