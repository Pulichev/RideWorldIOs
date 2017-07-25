//
//  Created by Владислав Пуличев on 17.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapController: UIViewController {
   
   var spotsFromDB = [SpotItem]()
   
   var spotDetailsForSendToPostsStripController: SpotItem!
   
   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var menuView: UIViewX!
   @IBOutlet weak var addNewSpotButton: FloatingActionButton!
   @IBOutlet weak var confirmNewSpotButton: UIButton!
   @IBOutlet weak var cancelNewSpotButton: UIButton!
   
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
         self.loadSpotsOnMap()
      }
      
      closeMenu()
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
         newSpotController.spotLatitude = pinForNewSpot.coordinate.latitude //Passing latitude
         newSpotController.spotLongitude = pinForNewSpot.coordinate.longitude //Passing latitude
         
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
   
   fileprivate var weAddingSpot: Bool! = false // this we will use in adding new spot
   // to show pin of new spot or not
   fileprivate var pinForNewSpot: MKPointAnnotation!
   
   fileprivate func closeMenu() {
      menuView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
   }
}

// MARK: - MKMapViewDelegate
extension MapController: MKMapViewDelegate {
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
         annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)// MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
         annotationView?.canShowCallout = true
      } else {
         annotationView!.annotation = annotation
      }
      
      // customize pin image
      let customPin = annotation as! CustomPin
      annotationView!.image = getProperImage(for: customPin.spotItem.type)
      
      return annotationView
   }
   
   private func getProperImage(for type: Int) -> UIImage {
      switch type {
      case 0:
         return UIImage(named: "Street")!
      case 1:
         return UIImage(named: "Park")!
      case 2:
         return UIImage(named: "Dirt")!
      default:
         return UIImage(named: "Street")!
      }
   }
   
   private func configureDetailView(annotationView: MKAnnotationView, spotPin: SpotItem) {
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
   
   // func for adding new spot. It is placing new pin on map, that will
   // move on every drag of map.
   func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      if weAddingSpot {
         removeOldNewSpotAnnotation()
         addMewSpotAnnotation()
      }
   }
   
   fileprivate func removeOldNewSpotAnnotation() {
      let pins = mapView.annotations
      
      for pin in pins {
         if let mkPin = pin as? MKPointAnnotation {
            if mkPin.accessibilityLabel == "NewSpotAnnotation" {
               mapView.removeAnnotation(pin)
            }
         }
      }
   }
   
   fileprivate func addMewSpotAnnotation() {
      let annotation = MKPointAnnotation()
      annotation.coordinate = mapView.centerCoordinate
      annotation.title = "New spot"
      annotation.subtitle = "will be added here"
      annotation.accessibilityLabel = "NewSpotAnnotation" // using this for detection
      pinForNewSpot = annotation
      
      self.mapView.addAnnotation(annotation)
   }
}

// MARK: - CLLocationManagerDelegate
extension MapController: CLLocationManagerDelegate {
   func setStartRegion() {
      let span: MKCoordinateSpan = MKCoordinateSpanMake(0.1, 0.1)
      var myLocation: CLLocationCoordinate2D
      if let coordinates = locationManager.location?.coordinate {
         myLocation = CLLocationCoordinate2DMake(coordinates.latitude,
                                                 coordinates.longitude)
      } else {
         myLocation = CLLocationCoordinate2DMake(55.925314,
                                                 37.824127)
      }
      
      let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
      mapView.setRegion(region, animated: true)
   }
   
   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
      if case .authorizedWhenInUse = status {
         manager.requestLocation()
      }
   }
   
   func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      mapView.showsUserLocation = true
   }
   
   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
      print("CLLocationManager error: \(error.localizedDescription)")
   }
   
   @IBAction func AddNewSpot(_ sender: FloatingActionButton) {
      
      // menu actions
      UIView.animate(withDuration: 0.3, animations: {
         if self.menuView.transform == .identity {
            self.closeMenu()
         } else {
            self.menuView.transform = .identity
         }
      })
      
      if !weAddingSpot { // if we first time tapped button
         weAddingSpot = true
         
         addMewSpotAnnotation()
         
         swapHidePropertyForButtonsForConfirming()
      }
   }
   
   @IBAction func confirmNewSpot(_ sender: UIButton) {
      let dist = distanceToNearestPin()
      
      if dist > 50.0 {
         weAddingSpot = false
         removeOldNewSpotAnnotation()
         swapHidePropertyForButtonsForConfirming()
         
         performSegue(withIdentifier: "addNewSpot", sender: self)
      } else {
         showAlertThatToCloseToExistingSpot()
      }
   }
   
   @IBAction func cancelNewSpot(_ sender: UIButton){
      weAddingSpot = false
      
      removeOldNewSpotAnnotation()
      
      swapHidePropertyForButtonsForConfirming()
   }
   
   private func distanceToNearestPin() -> Float {
      let pins = mapView.annotations
      var minDistance: CLLocationDistance = 1000000000.0
      
      for pin in pins {
         if !(pin is MKUserLocation) { // if not user location
            let coord = pin.coordinate
            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let newSpotLocation = CLLocation(latitude: pinForNewSpot.coordinate.latitude, longitude: pinForNewSpot.coordinate.longitude)
            
            let distance : CLLocationDistance = loc.distance(from: newSpotLocation)
            if (distance < minDistance && distance != 0.0)
               || minDistance == 1000000000.0 {
               minDistance = distance
            }
         }
      }
      
      return Float(minDistance)
   }
   
   private func showAlertThatToCloseToExistingSpot() {
      let alert = UIAlertController(title: "Error!",
                                    message: "You are trying to add spot to close to already existed. "
                                       + "Distance have to be more than 50 meters.",
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   private func swapHidePropertyForButtonsForConfirming() {
      if confirmNewSpotButton.isHidden {
         confirmNewSpotButton.isHidden = false
         cancelNewSpotButton.isHidden = false
      } else {
         confirmNewSpotButton.isHidden = true
         cancelNewSpotButton.isHidden = true
      }
   }
}

// MARK: - Part for hide and view navbar
extension MapController {
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      let titleView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
      titleView.contentMode = .scaleAspectFit
      titleView.image = UIImage(named: "rideWorldLogo.png")
      
      self.navigationItem.titleView = titleView
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      // Show the navigation bar on other view controllers
      navigationController?.setNavigationBarHidden(false, animated: animated)
   }
}

