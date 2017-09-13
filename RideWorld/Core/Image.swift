//
//  ResizeImage.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 10.03.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Photos

struct Image : Equatable {
   
   public let asset: PHAsset
   
   // MARK: - Initialization
   
   init(asset: PHAsset) {
      self.asset = asset
   }
}

// MARK: - UIImage

extension Image {
   public func uiImage(ofSize size: CGSize) -> UIImage? {
      let options = PHImageRequestOptions()
      options.isSynchronous = true
      
      var result: UIImage? = nil
      
      PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { (image, _) in
         result = image
      }
      
      return result
   }
   
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

// MARK: - Equatable

public func ==(lhs: Image, rhs: Image) -> Bool {
   return lhs.asset == rhs.asset
}

extension UIImage {
   var aspectRatio: Double {
      let height = self.size.height
      let width  = self.size.width
      
      return Double(height / width)
   }
}
