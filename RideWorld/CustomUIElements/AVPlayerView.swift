//
//  AVPlayerView.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 13.10.2017.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation

class AVPlayerView: UIView {
   override class var layerClass: AnyClass {
      return AVPlayerLayer.self
   }
}
