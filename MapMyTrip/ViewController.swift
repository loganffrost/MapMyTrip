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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        isRecording = false
        
        getPermissions()
        setUpMap()
        setupUserTrackingButtonAndScaleView()
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
    
    
    // MARK: Actions
    @IBAction func saveCurrentTrack(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func stopPlayer(_ sender: Any) {
        recordButton.isEnabled = true
        pauseButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    @IBAction func pausePlayer(_ sender: Any) {
        recordButton.isEnabled = true
        stopButton.isEnabled = true
        pauseButton.isEnabled = false
    }
    
    @IBAction func startRecording(_ sender: Any) {
        recordButton.isEnabled = false
        stopButton.isEnabled = true
        pauseButton.isEnabled = true
        isRecording = true
    }
}

