//
//  ResizeImage.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 10.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import Foundation

struct Image {
   static func resize(_ image: UIImage, targetSize: CGSize) -> UIImage {
      let size = image.size
      
      let widthRatio  = targetSize.width  / image.size.width
      let heightRatio = targetSize.height / image.size.height
      
      // Figure out what our orientation is, and use that to form the rectangle
      var newSize: CGSize
      if(widthRatio > heightRatio) {
         newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
      } else {
         newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
      }
      
      // This is the rect that we've calculated out and this is what is actually used below
      let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
      
      // Actually do the resizing to the rect using the ImageContext stuff
      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
      image.draw(in: rect)
      
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      return newImage!
   }
   
   static func addBlur(on imageView: UIImageView) {
      let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
      let blurEffectView = UIVisualEffectView(effect: blurEffect)
      blurEffectView.frame = imageView.bounds
      blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      imageView.addSubview(blurEffectView)
   }
}
