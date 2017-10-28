//
//  CustomPin.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit
import Cluster

class CustomPin: Annotation {
  
  var spotItem: SpotItem!
//  var coordinate: CLLocationCoordinate2D
//  var title: String? = ""
  
//  init(coordinate: CLLocationCoordinate2D) {
//    self.coordinate = coordinate
//  }
}

class BorderedClusterAnnotationView: ClusterAnnotationView {
  let borderColor: UIColor
  
  init(annotation: MKAnnotation?, reuseIdentifier: String?, type: ClusterAnnotationType, borderColor: UIColor) {
    self.borderColor = borderColor
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier, type: type)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func configure(with type: ClusterAnnotationType) {
    super.configure(with: type)
    
    switch type {
    case .image:
      layer.borderWidth = 0
    case .color:
      layer.borderColor = borderColor.cgColor
      layer.borderWidth = 2
    }
  }
}
