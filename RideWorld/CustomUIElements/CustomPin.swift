//
//  customPin.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 19.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit

class CustomPin: NSObject, MKAnnotation {
   var spotItem: SpotItem!
//   var title: String? = ""
   var coordinate: CLLocationCoordinate2D
   
   init(coordinate: CLLocationCoordinate2D) {
      self.coordinate = coordinate
   }
}
