//
//  ViewController.swift
//  MapMyTrip
//
//  Created by Alex on 12/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import os.log

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var stopButton: UIBarButtonItem!
    @IBOutlet weak var pauseButton: UIBarButtonItem!
    @IBOutlet weak var recordButton: UIBarButtonItem!
    @IBOutlet weak var saveTrackButton: UIBarButtonItem!
    
    // MARK: Properties
    var locationManager: CLLocationManager!
    var userLocation: CLLocation!
    var isRecording: Bool!
    var transportMode: Int!
    var defaults : UserDefaults!
    var recordingThresholds: [Int] = [5,10,10,25,25, 50, 100, 100]
    var recordingThreshold: Int!
    var mode: Int!
    var visitedLocations: [CLLocation]!
    var previousLocation : CLLocation!
    var newLocation : CLLocation!
    
    // MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        mapView.delegate = self
        isRecording = false
        
        // Set up array for visted locations
        visitedLocations = [CLLocation]()
        
        // Get user defaults
        defaults = UserDefaults.standard
        mode = defaults.integer(forKey:"travelMode")
        recordingThreshold = recordingThresholds[mode]
        
        getPermissions()
        setUpMap()
        setupUserTrackingButtonAndScaleView()
        
      //  loadLocations()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if isRecording {
        var distance: CLLocationDistance = 0.0
        // Check for location existing in locations
        guard let currentLocation = locations.first else {
            return
        }
        // Check for sensible distance from most recent location
        // Check that this is not the first location
        if visitedLocations.count > 1 {
            // Get last visitedLocation and find distance from currentLocation
            previousLocation = visitedLocations.last
            distance = currentLocation.distance(from: previousLocation!)
            // print("Distance: \(distance)")
            // Do not record locations within 25 metres of previous
            if distance > Double(recordingThreshold)
            {
                // Add currentLocation to end of visitedLocations array
                visitedLocations.append(currentLocation)
            }
        } else {
            visitedLocations.append(currentLocation)
        }
        
        if (visitedLocations.last as CLLocation?) != nil {
            var coordinates = visitedLocations.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
            let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
        }

    }
    }
    
    func getPermissions() {
        // user activated automatic authorization info mode
        var status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .denied || status == .authorizedWhenInUse {
            // present an alert indicating location authorization required
            // and offer to take the user to Settings for the app via
            // UIApplication -openUrl: and UIApplicationOpenSettingsURLString
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func setUpMap() {
        mapView.mapType = .standard
        mapView.userTrackingMode = MKUserTrackingMode(rawValue: 2)!
        mapView.showsCompass = true
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func setupUserTrackingButtonAndScaleView() {
        mapView.showsUserLocation = true
        
        let button = MKUserTrackingButton(mapView: mapView)
        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        let scale = MKScaleView(mapView: mapView)
        scale.legendAlignment = .trailing
        scale.translatesAutoresizingMaskIntoConstraints = false
        scale.scaleVisibility = .visible
        view.addSubview(scale)
        
        NSLayoutConstraint.activate([button.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -54),
                                     button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                                     scale.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -10),
                                     scale.centerYAnchor.constraint(equalTo: button.centerYAnchor)])
    }
    
    // MARK: File operation methods
     func saveLocations() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(visitedLocations, toFile: Location.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Locations successfully saved", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save meals...", log: OSLog.default, type: .error)
        }
    }
    

    static func loadWidgetDataArray(unarchivedObject: Data) -> [Location] {
        return try! NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, Location.self], from: unarchivedObject) as! [Location] }
    
    // MARK: Actions
    func onReturnFromSettings(mode: Int) {
        self.mode = mode
        self.recordingThreshold = self.recordingThresholds[mode]
        // print("Threshold - \(recordingThreshold)")
    }
    
    @IBAction func saveCurrentTrack(_ sender: UIBarButtonItem) {
        saveLocations()
    }
    
    
    @IBAction func printLocations(_ sender: Any) {
        for location in visitedLocations {
            let altitude = location.altitude
            let timestamp = location.timestamp
            print("Location: \(altitude)")
        }
    }
    
    @IBAction func stopPlayer(_ sender: Any) {
        recordButton.isEnabled = true
        pauseButton.isEnabled = true
        stopButton.isEnabled = false
        isRecording = false
    }
    
    @IBAction func pausePlayer(_ sender: Any) {
        recordButton.isEnabled = true
        stopButton.isEnabled = true
        pauseButton.isEnabled = false
        isRecording = false
    }
    
    @IBAction func startRecording(_ sender: Any) {
        recordButton.isEnabled = false
        stopButton.isEnabled = true
        pauseButton.isEnabled = true
        isRecording = true
        
        self.recordingThreshold = self.recordingThresholds[mode]
    }
    
    func addAnnotationsOnMap(locationToPoint : CLLocation) {
        //calculation for location selection and pointing annotation
        if (previousLocation as CLLocation?) != nil{
            //case if previous location exists
            if previousLocation.distance(from: newLocation) > 200 {
                addAnnotationsOnMap(locationToPoint: newLocation)
                previousLocation = newLocation
            }
        }else{
            //in case previous location doesn't exist
            addAnnotationsOnMap(locationToPoint: newLocation)
            previousLocation = newLocation
        }
    }
    
    
    // MARK: Overrides
    override func viewDidAppear(_ animated: Bool) {
        // Set up
        mode = defaults.integer(forKey:"travelMode")
        recordingThreshold = recordingThresholds[mode]
    }
}

