//
//  VideoContainerView.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 26.06.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

class VideoContainerView: UIView {
   var playerLayer: CALayer?
   
   override func layoutSublayers(of layer: CALayer) {
      super.layoutSublayers(of: layer)
      playerLayer?.frame = self.bounds
   }
}
