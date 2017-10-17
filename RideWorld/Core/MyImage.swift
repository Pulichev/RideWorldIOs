//
//  ResizeImage.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 10.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

struct MyImage {
  
  static func resize(sourceImage: UIImage, toWidth: CGFloat) -> (image: UIImage, aspectRatio: Double) {
    let oldWidth = sourceImage.size.width
    let scaleFactor = toWidth / oldWidth
    
    let newHeight = sourceImage.size.height * scaleFactor
    
    let aspectRatio = newHeight / toWidth
    
    UIGraphicsBeginImageContext(CGSize(width: toWidth, height: newHeight))
    sourceImage.draw(in: CGRect(x: 0, y: 0, width: toWidth, height: newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return (newImage!, Double(aspectRatio))
  }
}

extension UIImage {
  
  var aspectRatio: Double {
    let height = self.size.height
    let width  = self.size.width
    
    return Double(height / width)
  }
}
