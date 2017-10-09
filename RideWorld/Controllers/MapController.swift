//
//  Created by Владислав Пуличев on 17.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Instructions

class MapController: UIViewController {
   
   var spotsFromDB = [SpotItem]()
   
   var spotDetailsForSendToPostsStripController: SpotItem!
   
   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var menuView: UIViewX!
   @IBOutlet weak var addNewSpotButton: FloatingActionButton!
   
   lazy var locationManager: CLLocationManager = {
      let manager = CLLocationManager()
      manager.delegate = self
      manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      return manager
   }()
   
   let coachMarksController = CoachMarksController() // onboard tips controller
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      self.coachMarksController.dataSource = self
      
      DispatchQueue.main.async {
         self.mapViewInitialize()
         self.loadSpotsOnMap()
      }
      
      closeMenu()
   }
   
   private func startCoachingIfNeeded() {
      let defaults = UserDefaults.standard
      if (defaults.object(forKey: "firstLaunchOfMap") as? Bool) == nil {
         // if it is first launch, this key will not be set upped
         
         self.coachMarksController.start(on: self)
      }
   }
   
   override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      
      startCoachingIfNeeded()
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
         let pin = CustomPin(coordinate: CLLocationCoordinate2DMake(spot.latitude, spot.longitude))

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
      let altitude: CLLocationDistance = 1000
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
         newSpotController.spotLatitude = pinForNewSpot.coordinate.latitude // passing latitude
         newSpotController.spotLongitude = pinForNewSpot.coordinate.longitude // passing latitude
         newSpotController.cameForNewSpot = true
         newSpotController.spotInfoOnMapDelegate = self
         
      case "spotDetailsTapped":
         let postsStripController = (segue.destination as! PostsStripController)
         postsStripController.spotDetailsItem = spotDetailsForSendToPostsStripController
         postsStripController.cameFromSpotOrMyStrip = true // came from spot
         
      case "goToSpotInfo":
         let spotInfoController = (segue.destination as! SpotInfoController)
         spotInfoController.spotInfo = spotDetailsForSendToPostsStripController
         spotInfoController.spotInfoOnMapDelegate = self
         
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
      if !(view.annotation! is MKUserLocation)
         && view.annotation?.title! != NSLocalizedString("New spot", comment: "") {
      
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
         annotationView = SpotAnnotationView(annotation: annotation, reuseIdentifier: identifier)
         annotationView?.canShowCallout = false
      } else {
         annotationView!.annotation = annotation
      }
      
      // customize pin image
      let customPin = annotation as! CustomPin
      annotationView!.image = getProperImage(for: customPin.spotItem.type)
      annotationView!.centerOffset = CGPoint(x: 0, y: -33)
      
      return annotationView
   }
   
   func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
      if view is SpotAnnotationView {
         for subview in view.subviews {
            subview.removeFromSuperview()
         }
      }
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
      let spotAnnotationViewCallout = Bundle.main.loadNibNamed("SpotAnnotationViewCallout", owner: self, options: nil)!.last as! SpotAnnotationViewCallout
      
      spotAnnotationViewCallout.addPhoto(spot: spotPin)
      spotAnnotationViewCallout.goToInfoButton.addTarget(self, action: #selector(goToInfo), for: .touchDown)
      spotAnnotationViewCallout.goToPostsButton.addTarget(self, action: #selector(goToPosts), for: .touchDown)
      
      spotAnnotationViewCallout.center = CGPoint(x: annotationView.bounds.size.width / 2, y:  -spotAnnotationViewCallout.bounds.size.height * 0)
      annotationView.addSubview(spotAnnotationViewCallout)
      mapView.setCenter((annotationView.annotation?.coordinate)!, animated: true)
   }
   
   @objc func goToPosts(sender: UIButtonX) {
      sender.endTracking(nil, with: nil) // cz of segue this function will not be called
      // -> it will be like gray
      
      performSegue(withIdentifier: "spotDetailsTapped", sender: self)
   }
   
   @objc func goToInfo(sender: UIButtonX) {
      sender.endTracking(nil, with: nil) // cz of segue this function will not be called
      // -> it will be like gray
      
      performSegue(withIdentifier: "goToSpotInfo", sender: self)
   }
   
   // func for adding new spot. It is placing new pin on map, that will
   // move on every drag of map.
   func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      if weAddingSpot {
         removeOldNewSpotAnnotation()
         addNewSpotAnnotation()
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
   
   fileprivate func addNewSpotAnnotation() {
      let annotation = MKPointAnnotation()
      annotation.coordinate = mapView.centerCoordinate
      annotation.title = NSLocalizedString("New spot", comment: "")
      annotation.subtitle = NSLocalizedString("will be added here", comment: "")
      annotation.accessibilityLabel = "NewSpotAnnotation" // using this for detection
      pinForNewSpot = annotation
      
      mapView.addAnnotation(annotation)
   }
}

// MARK: - CLLocationManagerDelegate
extension MapController: CLLocationManagerDelegate {
   func setStartRegion() {
      let span: MKCoordinateSpan = MKCoordinateSpanMake(0.5, 0.5)
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
      // open/close menu and some actions with pin
      UIView.animate(withDuration: 0.3, animations: {
         if self.menuView.transform == .identity {
            self.weAddingSpot = false
            self.closeMenu()
            self.removeOldNewSpotAnnotation()
         } else {
            self.weAddingSpot = true
            self.addNewSpotAnnotation()
            self.menuView.transform = .identity
         }
      })
   }
   
   @IBAction func confirmNewSpot(_ sender: UIButton) {
      let dist = distanceToNearestPin()
      
      if dist > 50.0 {
         weAddingSpot = false
         UIView.animate(withDuration: 0.3, animations: {
            // return button to .identity
            self.addNewSpotButton.transform = .identity
            self.addNewSpotButton.backgroundColor = UIColor.myBlack()
            self.addNewSpotButton.borderWidth = 2.0
            self.addNewSpotButton.tintColor = UIColor.white
            
            self.closeMenu()
         })
         
         removeOldNewSpotAnnotation()
         
         performSegue(withIdentifier: "addNewSpot", sender: self)
      } else {
         showAlertThatToCloseToExistingSpot()
      }
   }
   
   @IBAction func cancelNewSpot(_ sender: UIButton){
      weAddingSpot = false
      UIView.animate(withDuration: 0.3, animations: {
         // return button to .identity
         self.addNewSpotButton.transform = .identity
         self.addNewSpotButton.backgroundColor = UIColor.myBlack()
         self.addNewSpotButton.borderWidth = 2.0
         self.addNewSpotButton.tintColor = UIColor.white
         
         self.closeMenu()
      })
      
      removeOldNewSpotAnnotation()
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
      let alert = UIAlertController(title: NSLocalizedString("Error!", comment: ""),
                                    message: NSLocalizedString("You are trying to add spot too close to already existed. Distance have to be more than 50 meters.", comment: ""),
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
}

extension MapController: SpotInfoOnMapDelegate {
   func placeSpotOnMap(_ spot: SpotItem) {
      if let index = spotsFromDB.index(where: { $0.key == spot.key }) {
         let pin = CustomPin(coordinate: CLLocationCoordinate2DMake(spot.latitude, spot.longitude))
         pin.spotItem = spot
         
         // remove old annotation
         // find old annotation
         let oldAnnotation = mapView.annotations.first(where: { !($0 is MKUserLocation)
            && ($0 as! CustomPin).spotItem.key == spot.key })!
         spotsFromDB[index] = spot
         mapView.removeAnnotation(oldAnnotation)
         // add updated annotation
         mapView.addAnnotation(pin)
      } else {
         // create spot
         spotsFromDB.append(spot)
         
         let pin = CustomPin(coordinate: CLLocationCoordinate2DMake(spot.latitude, spot.longitude))
         pin.spotItem = spot
         
         mapView.addAnnotation(pin)
      }
   }
}

// MARK: - Part for hide and view navbar
extension MapController {
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      navigationController?.setNavigationBarHidden(true, animated: animated)
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      
      self.coachMarksController.stop(immediately: true)
      let defaults = UserDefaults.standard
      defaults.set(false, forKey: "firstLaunchOfMap")
      
      // Show the navigation bar on other view controllers
      navigationController?.setNavigationBarHidden(false, animated: animated)
   }
}

// MARK: - Onboard instructions
extension MapController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
   func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
      return 1
   }
   
   func coachMarksController(_ coachMarksController: CoachMarksController,
                             coachMarkAt index: Int) -> CoachMark {
         let addNewSpotButtonView = addNewSpotButton.imageView
         
      return coachMarksController.helper.makeCoachMark(for: addNewSpotButtonView) { (frame: CGRect) -> UIBezierPath in
         // This will create an arc on new spot button
         return UIBezierPath(arcCenter: CGPoint(x: frame.midX, y: frame.midY), radius: 34.0, startAngle: 0, endAngle: CGFloat(2 * Double.pi), clockwise: true)
      }
   }
   
   func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
      let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
      
      coachViews.bodyView.hintLabel.text = NSLocalizedString("You can add new spot by tapping this button!", comment: "")
      coachViews.bodyView.nextLabel.text = NSLocalizedString("Ok!", comment: "")
      
      return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
   }
}
