//
//  Created by Владислав Пуличев on 17.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MainFormController: UIViewController {
    var backendless: Backendless!
    
    var spotsFromDB = [SpotDetails]()
    
    var spotDetailsForSendToSpotDetailsController: SpotDetails!
    
    @IBOutlet weak var mapView: MKMapView!
    
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backendless = Backendless.sharedInstance()
        
        mapViewInitialize()
        loadSpotsOnMap()
    }
    
    func mapViewInitialize() {
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        setStartRegion()
        
        //Some map customisation
        //displayAdditionalOptions()
        //displayInFlyoverMode()
        //openMapInTransitMode()
    }
    
    func loadSpotsOnMap() {
        let whereClause = ""
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        var error: Fault?
        let spotList = backendless.data.of(SpotDetails.ofClass()).find(dataQuery, fault: &error)
        
        if error != nil
        {
            print("Server reported an error: \(spotList)")
        }
        
        spotsFromDB = spotList?.data as! [SpotDetails]
        
        addPinsOnMap(spotList: spotsFromDB)
    }
    
    func addPinsOnMap(spotList: [SpotDetails]) {
        for spot in spotList {
            let pin = CustomPin()
            pin.coordinate = CLLocationCoordinate2DMake(spot.latitude, spot.longitude)
            pin.title = spot.spotName
            pin.subtitle = spot.spotDescription
            pin.spotDetails = spot
            
            mapView.addAnnotation(pin)
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(nil, forKey: "userLoggedIn")
        defaults.synchronize()
        
        self.performSegue(withIdentifier: "userLogouted", sender: self)
    }
    
    func displayAdditionalOptions() {
        mapView.showsCompass = true
        mapView.showsTraffic = true
        mapView.showsScale = true
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
        
        let options = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeTransit]
        
        MKMapItem.openMaps(with: [start, destination], launchOptions: options)
    }
}

//MARK: - MKMapViewDelegate
extension MainFormController: MKMapViewDelegate {
    //download pictures and etc on tap on pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let customPin = view.annotation as! CustomPin
        
        configureDetailView(annotationView: view, spotPin: customPin.spotDetails)
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
    
    func configureDetailView(annotationView: MKAnnotationView, spotPin: SpotDetails) {
        let width = 200
        let height = 200
        
        let snapshotView = UIView()
        let views = ["snapshotView": snapshotView]
        snapshotView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[snapshotView(200)]", options: [], metrics: nil, views: views))
        snapshotView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[snapshotView(200)]", options: [], metrics: nil, views: views))
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        
        let spotDetailsPhotoURL = "https://api.backendless.com/4B2C12D1-C6DE-7B3E-FFF0-80E7D3628C00/v1/files/media/spotMainPhotoURLs/" + (spotPin.objectId!).replacingOccurrences(of: "-", with: "") + ".jpeg"
        
        DispatchQueue.global(qos: .userInitiated).async(execute: {
            if let imageURL = URL(string: spotDetailsPhotoURL) {
                if let imageData = NSData(contentsOf: imageURL) {
                    let logo = UIImage(data: imageData as Data)
                    DispatchQueue.main.async(execute: {
                        imageView.image = logo
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
        self.spotDetailsForSendToSpotDetailsController = customAnnotation.spotDetails
        
        self.performSegue(withIdentifier: "spotDetailsTapped", sender: self)
    }
}

//MARK: - CLLocationManagerDelegate
extension MainFormController: CLLocationManagerDelegate {
    func setStartRegion() {
        let span:MKCoordinateSpan = MKCoordinateSpanMake(0.1, 0.1)
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(55.925314, 37.824127)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
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
            spotDetailsController.spotDetails = spotDetailsForSendToSpotDetailsController
        }
    }
}
