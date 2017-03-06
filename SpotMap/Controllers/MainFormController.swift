//
//  Created by Владислав Пуличев on 17.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class MainFormController: UIViewController {
    
    var spotsFromDB = [SpotDetailsItem]()
    
    var spotDetailsForSendToSpotDetailsController: SpotDetailsItem!
    
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
    
    //part for hide and view navbar from this navigation controller
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation bar on the this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func mapViewInitialize() {
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        setStartRegion()
        
        //Some map customisation
        displayAdditionalOptions()
        //displayInFlyoverMode()
        //openMapInTransitMode()
    }
    
    func loadSpotsOnMap() {
        let ref = FIRDatabase.database().reference(withPath: "MainDataBase/spotdetails")
        
        ref.queryOrdered(byChild: "key").observe(.value, with: { snapshot in
            var newItems: [SpotDetailsItem] = []
            
            for item in snapshot.children {
                let spotDetailsItem = SpotDetailsItem(snapshot: item as! FIRDataSnapshot)
                newItems.append(spotDetailsItem)
            }
            
            self.spotsFromDB = newItems
            self.addPinsOnMap()
        })
    }
    
    func addPinsOnMap() {
        for spot in self.spotsFromDB {
            let pin = CustomPin()
            pin.coordinate = CLLocationCoordinate2DMake(spot.latitude, spot.longitude)
            pin.title = spot.name
            pin.subtitle = spot.description
            pin.spotDetailsItem = spot
            
            mapView.addAnnotation(pin)
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        do {
            try FIRAuth.auth()!.signOut()
            self.performSegue(withIdentifier: "userLogouted", sender: self)
        } catch {
            print("Error while signing out!")
        }
    }
    
    func displayAdditionalOptions() {
        mapView.showsCompass = false
        mapView.showsTraffic = true
        //mapView.showsScale = true
    }
    
    func displayInFlyoverMode() {
        mapView.mapType = .satelliteFlyover
        mapView.showsBuildings = true
        
        let location = CLLocationCoordinate2D(latitude: 51.50722, longitude: -0.12750)
        let altitude: CLLocationDistance  = 500
        let heading: CLLocationDirection = 90
        let pitch = CGFloat(45)
        let camera = MKMapCamera(lookingAtCenter: location, fromDistance: altitude, pitch: pitch, heading: heading)
        
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
}

// MARK: - MKMapViewDelegate
extension MainFormController: MKMapViewDelegate {
    //download pictures and etc on tap on pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let customPin = view.annotation as! CustomPin
        
        configureDetailView(annotationView: view, spotPin: customPin.spotDetailsItem)
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
    
    func configureDetailView(annotationView: MKAnnotationView, spotPin: SpotDetailsItem) {
        let width = 200
        let height = 200
        
        let snapshotView = UIView()
        let views = ["snapshotView": snapshotView]
        snapshotView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[snapshotView(200)]", options: [], metrics: nil, views: views))
        snapshotView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[snapshotView(200)]", options: [], metrics: nil, views: views))
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        
        let storage = FIRStorage.storage()
        // Create a reference from a Google Cloud Storage URI
        let url = "gs://spotmap-e3116.appspot.com/media/spotMainPhotoURLs/" + spotPin.key + ".jpeg"
        let spotDetailsPhotoURL = storage.reference(forURL: url)
        
        DispatchQueue.global(qos: .userInitiated).async(execute: {
            spotDetailsPhotoURL.data(withMaxSize: 3 * 1024 * 1024) { data, error in
                if let error = error {
                    // Uh-oh, an error occurred!
                    let image = UIImage(contentsOfFile: "plus-512.gif")
                    DispatchQueue.main.async(execute: {
                        imageView.image = image
                    })
                } else {
                    let image = UIImage(data: data!)
                    DispatchQueue.main.async(execute: {
                        imageView.image = image
                    })
                }
            }
        })
        
        imageView.layer.cornerRadius = imageView.frame.size.height / 8
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 0
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        snapshotView.addSubview(imageView)
        
        annotationView.detailCalloutAccessoryView = snapshotView
        
        let btn = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = btn
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("details tapped")
        let customAnnotation = view.annotation as! CustomPin
        self.spotDetailsForSendToSpotDetailsController = customAnnotation.spotDetailsItem
        
        self.performSegue(withIdentifier: "spotDetailsTapped", sender: self)
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
        
        self.mapView.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("CLLocationManager error: \(error.localizedDescription)")
    }
    
    @IBAction func AddNewSpot(_ sender: Any) {
        self.performSegue(withIdentifier: "addNewSpot", sender: self)
    }
    
    //Overriding function for passing data through two views
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "addNewSpot") {
            let newSpotController = (segue.destination as! NewSpotController)
            newSpotController.spotLatitude = mapView.userLocation.coordinate.latitude //Passing latitude
            newSpotController.spotLongitude = mapView.userLocation.coordinate.longitude //Passing latitude
        }
        
        if(segue.identifier == "spotDetailsTapped") {
            let spotDetailsController = (segue.destination as! SpotDetailsController)
            spotDetailsController.spotDetailsItem = spotDetailsForSendToSpotDetailsController
        }
    }
}
