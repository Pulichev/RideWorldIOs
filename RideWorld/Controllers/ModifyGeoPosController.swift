//
//  ModifyGeoPosController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 30.08.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit

protocol GeoPosDelegate: class {
  func sendGeoPos(_ latitude: Double, _ longitude: Double)
}

class ModifyGeoPosController: UIViewController, MKMapViewDelegate {
  
  weak var delegateNewGeoPos: GeoPosDelegate?
  
  @IBOutlet weak var mapView: MKMapView!
  var latitude: Double!
  var longitude: Double!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    mapView.delegate = self
    
    setFocusToSourceLocation()
    addNewSpotAnnotation()
  }
  
  private func setFocusToSourceLocation() {
    let span: MKCoordinateSpan = MKCoordinateSpanMake(0.1, 0.1)
    var myLocation: CLLocationCoordinate2D
    
    myLocation = CLLocationCoordinate2DMake(latitude,
                                            longitude)
    
    let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
    
    mapView.setRegion(region, animated: true)
  }
  
  @IBAction func saveButtonTapped(_ sender: Any) {
    let annotation = mapView.annotations.first!
    delegateNewGeoPos!.sendGeoPos(annotation.coordinate.latitude,
                                  annotation.coordinate.longitude)
    
    _ = navigationController?.popViewController(animated: true)
  }
  
  // func for moving pin
  func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    removeOldAnnotation()
    addNewSpotAnnotation()
  }
  
  fileprivate func removeOldAnnotation() {
    let annotations = mapView.annotations
    mapView.removeAnnotations(annotations)
  }
  
  fileprivate func addNewSpotAnnotation() {
    let annotation = MKPointAnnotation()
    annotation.coordinate = mapView.centerCoordinate
    
    mapView.addAnnotation(annotation)
  }
}
