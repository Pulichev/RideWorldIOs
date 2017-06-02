//
//  Created by Владислав Пуличев on 17.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Cluster

class MainFormController: UIViewController {
   
   var spotsFromDB = [SpotItem]()
   
   var spotDetailsForSendToPostsStripController: SpotItem!
   
   @IBOutlet weak var mapView: MKMapView!
   
   lazy var locationManager: CLLocationManager = {
      let manager = CLLocationManager()
      manager.delegate = self
      manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      return manager
   }()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      DispatchQueue.main.async {
         self.mapViewInitialize()
         //MigratingDataFromBELToFireBase.migrate()
         self.loadSpotsOnMap()
      }
   }
   
   func mapViewInitialize() {
      mapView.delegate = self
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBest
      locationManager.distanceFilter = 10
      locationManager.desiredAccuracy = 5
      locationManager.activityType = .automotiveNavigation
      locationManager.requestWhenInUseAuthorization()
      locationManager.startUpdatingLocation()
      
      setStartRegion()
      
      //Some map customisation
      displayAdditionalOptions()
      //displayInFlyoverMode()
      //openMapInTransitMode()
   }
   
   func loadSpotsOnMap() {
      Spot.getAll() { spotsList in
         self.spotsFromDB = spotsList
         self.addPinsOnMap()
      }
   }
   
   func addPinsOnMap() {
      for spot in spotsFromDB {
         let pin = CustomPin()
         pin.coordinate = CLLocationCoordinate2DMake(spot.latitude, spot.longitude)
         pin.title = spot.name
         pin.subtitle = spot.description
         pin.spotItem = spot
         
         mapView.addAnnotation(pin)
      }
   }
   
   @IBAction func logoutButtonTapped(_ sender: Any) {
      if User.signOut() { // if no errors
         performSegue(withIdentifier: "fromMainFormToLogin", sender: self)
      }
   }
   
   func displayAdditionalOptions() {
      //mapView.showsCompass = false
      //mapView.showsTraffic = true
      //mapView.showsScale = true
   }
   
   func displayInFlyoverMode() {
      mapView.mapType = .satelliteFlyover
      mapView.showsBuildings = true
      
      let location = CLLocationCoordinate2D(latitude: 51.50722, longitude: -0.12750)
      let altitude: CLLocationDistance  = 500
      let heading: CLLocationDirection = 90
      let pitch = CGFloat(45)
      let camera = MKMapCamera(lookingAtCenter: location,
                               fromDistance: altitude, pitch: pitch, heading: heading)
      
      mapView.setCamera(camera, animated: true)
   }
   
   func openMapInTransitMode() {
      let startLocation = CLLocationCoordinate2D(latitude: 51.50722, longitude: -0.12750)
      let startPlacemark = MKPlacemark(coordinate: startLocation, addressDictionary: nil)
      let start = MKMapItem(placemark: startPlacemark)
      
      let destinationLocation = CLLocationCoordinate2D(latitude: 51.5149001, longitude: -0.1118255)
      let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
      let destination = MKMapItem(placemark: destinationPlacemark)
      
      let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit]
      
      MKMapItem.openMaps(with: [start, destination], launchOptions: options)
   }
   
   //Overriding function for passing data through two views
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "addNewSpot":
         let newSpotController = (segue.destination as! NewSpotController)
         newSpotController.spotLatitude = mapView.userLocation.coordinate.latitude //Passing latitude
         newSpotController.spotLongitude = mapView.userLocation.coordinate.longitude //Passing latitude
         
      case "spotDetailsTapped":
         let postsStripController = (segue.destination as! PostsStripController)
         postsStripController.spotDetailsItem = spotDetailsForSendToPostsStripController
         postsStripController.cameFromSpotOrMyStrip = true // came from spot
         
      case "goToSpotInfo":
         let spotInfoController = (segue.destination as! SpotInfoController)
         spotInfoController.spotInfo = spotDetailsForSendToPostsStripController
      default: break
      }
   }
}

// MARK: - MKMapViewDelegate
extension MainFormController: MKMapViewDelegate {
   //download pictures and etc on tap on pin
   func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
      if !(view.annotation! is MKUserLocation) {
         let customPin = view.annotation as! CustomPin
         spotDetailsForSendToPostsStripController = customPin.spotItem
         
         configureDetailView(annotationView: view, spotPin: customPin.spotItem)
      }
   }
   
   func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      if annotation is MKUserLocation {
         return nil
      }
      
      if !(annotation is CustomPin) {
         return nil
      }
      
      let identifier = "CustomPin"
      
      var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
      if annotationView == nil {
         annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
         annotationView?.canShowCallout = true
      } else {
         annotationView!.annotation = annotation
      }
      
      return annotationView
   }
   
   func configureDetailView(annotationView: MKAnnotationView, spotPin: SpotItem) {
      let pinfoView = PinInfoView()
      pinfoView.addPhoto(spot: spotPin)
      pinfoView.goToInfoButton.addTarget(self, action: #selector(goToInfo), for: .touchDown)
      pinfoView.goToPostsButton.addTarget(self, action: #selector(goToPosts), for: .touchDown)
      
      annotationView.detailCalloutAccessoryView = pinfoView
   }
   
   func goToPosts() {
      performSegue(withIdentifier: "spotDetailsTapped", sender: self)
   }
   
   func goToInfo() {
      performSegue(withIdentifier: "goToSpotInfo", sender: self)
   }
}

// MARK: - CLLocationManagerDelegate
extension MainFormController: CLLocationManagerDelegate {
   func setStartRegion() {
      let span: MKCoordinateSpan = MKCoordinateSpanMake(0.1, 0.1)
      let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(55.925314, 37.824127)
      let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
      mapView.setRegion(region, animated: true)
   }
   
   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
      if case .authorizedWhenInUse = status {
         manager.requestLocation()
      }
   }
   
   func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      //        let location = locations[0]
      
      mapView.showsUserLocation = true
   }
   
   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
      print("CLLocationManager error: \(error.localizedDescription)")
   }
   
   @IBAction func AddNewSpot(_ sender: Any) {
      if distanceToNearestPin() > 50.0 {
         performSegue(withIdentifier: "addNewSpot", sender: self)
      } else {
         showAlertThatToCloseToExistingSpot()
      }
   }
   
   private func distanceToNearestPin() -> Float {
      let pins = mapView.annotations
      //let currentLocation = mapView.userLocation.location!
      var minDistance: CLLocationDistance = 0.0
      
      for pin in pins {
         let coord = pin.coordinate
         let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
         
         let distance : CLLocationDistance = locationManager.location!.distance(from: loc)
         
         if distance < minDistance || minDistance == 0.0 {
            minDistance = distance
         }
      }
      
      return Float(minDistance)
   }
   
   private func showAlertThatToCloseToExistingSpot() {
      let alert = UIAlertController(title: "Error!",
                                    message: "You are trying to add spot to close to already existed",
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
}

// MARK: - Part for hide and view navbar
extension MainFormController {
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      self.navigationItem.title = "Ride World" // navbar title
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      // Show the navigation bar on other view controllers
      navigationController?.setNavigationBarHidden(false, animated: animated)
   }
}

