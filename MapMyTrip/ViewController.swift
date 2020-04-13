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
    // MARK: Properties
    var locationManager: CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.delegate = self;
        
        // user activated automatic authorization info mode
        var status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .denied || status == .authorizedWhenInUse {
               // present an alert indicating location authorization required
               // and offer to take the user to Settings for the app via
               // UIApplication -openUrl: and UIApplicationOpenSettingsURLString
               locationManager.requestAlwaysAuthorization()
               locationManager.requestWhenInUseAuthorization()
           }
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }


}

