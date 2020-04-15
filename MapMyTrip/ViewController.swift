//
//  ViewController.swift
//  MapMyTrip
//
//  Created by Alex on 12/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

// TODO: Add show tracks option to Settings

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var stopButton: UIBarButtonItem!
    @IBOutlet weak var pauseButton: UIBarButtonItem!
    @IBOutlet weak var recordButton: UIBarButtonItem!
    @IBOutlet weak var printButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // MARK: Properties
    var locationManager: CLLocationManager!
    var userLocation: CLLocation!
    var isRecording: Bool!
    var transportMode: Int!
    var defaults : UserDefaults!
    var recordingThresholds: [Int] = [1,5,10,25,25,50,100,100]
    var recordingThreshold: Int!
    var mode: Int!
    var destroyOnSave: Bool!
    var visitedLocations: [CLLocation]!
    var previousLocation : CLLocation!
    var newLocation : CLLocation!
    
    // var places: [NSManagedObject] = []
    
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
        destroyOnSave = defaults.bool(forKey: "destroyOnSave")
        recordingThreshold = recordingThresholds[mode]
        
        setupButtons()
        getPermissions()
        setUpMap()
        setupUserTrackingButtonAndScaleView()
    }
    
    // MARK:  Events
    // Plot currently active track when map loads
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        plotCurrentTrack()
    }
    
    // Called when CLLocationManager detects a change in location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Check whether recording is triggered
        
        if isRecording {
            var distance: CLLocationDistance!
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
                
                // Do not record locations within threshold of previous
                if distance > Double(recordingThreshold)
                {
                    // Add currentLocation to end of visitedLocations array
                    visitedLocations.append(currentLocation)
                    saveCurrentLocation(location: currentLocation)
                }
            } else {
                visitedLocations.append(currentLocation)
            }
            // then update overlay
            plotCurrentTrack()
        }
    }
    
    // MARK: Event Overrides
    override func viewDidAppear(_ animated: Bool) {
        // Set up
        mode = defaults.integer(forKey:"travelMode")
        recordingThreshold = recordingThresholds[mode]
    }
    
    // MARK: Functions
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // Prepare visitedLocations for saving
    func prepareWriteString() -> String{
        // Intiialise data string
        var outputString = ""
        var outputData: [String] = []
        for place in visitedLocations {
            
            let placeString = makeString(place: place)
            outputData.append(placeString)
        }
        outputString = outputData.joined(separator: "\n")
        return outputString
    }
    
    // Make String from a place
    func makeString(place :CLLocation) -> String{
        // Sart with an empty string
        // and a CLocation
        let latitude = place.coordinate.latitude
        let longitude = place.coordinate.longitude
        let timestamp = place.timestamp
        let elevation = place.altitude
        let haccuracy = place.horizontalAccuracy
        let vaccuracy = place.verticalAccuracy
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timStr = formatter.string(from: timestamp)
        
        // Convert to String data
        let latStr = "\(latitude)"
        let longStr = "\(longitude)"
        let haccStr = "\(haccuracy)"
        let vaccStr = "\(vaccuracy)"
        let eleStr = "\(elevation)"
        
        var  dataArray: [String] = []
        dataArray.append(latStr)
        dataArray.append(longStr)
        dataArray.append(haccStr)
        dataArray.append(vaccStr)
        dataArray.append(eleStr)
        dataArray.append(timStr)
        
        let dataString = dataArray.joined(separator: ",")
        return dataString
    }
    
    
    
    // Plots track loaded from visitedLocations array
    func plotCurrentTrack() {
        // if (visitedLocations.last as CLLocation?) != nil {
        var coordinates = visitedLocations.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        //  }
    }
    
    // Gets permisiions for location services
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
    
    func setupButtons() {
        pauseButton.isEnabled = false
        printButton.isEnabled = false
        recordButton.isEnabled = true
        stopButton.isEnabled = false
        saveButton.isEnabled = false
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.purple
        renderer.lineWidth = 3.0
        renderer.lineDashPattern = .some([4,4])
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
    
    
    
    
    // MARK: Actions
    func onReturnFromSettings(mode: Int) {
        self.mode = mode
        self.recordingThreshold = self.recordingThresholds[mode]
        // print("Threshold - \(recordingThreshold)")
    }
    
    @IBAction func saveCurrentTrack(_ sender: UIBarButtonItem) {
        // save(visitedLocations: visitedLocations)
    }
    
    @IBAction func printLocations(_ sender: Any) {
        for location in visitedLocations {
            let altitude = location.altitude
            let timestamp = location.timestamp
            print("Location: \(altitude)")
        }
    }
    
    @IBAction func savePlaces(_ sender: UIBarButtonItem) {
        let dataString : String = prepareWriteString()
        
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd_MM_yy_HH_mm"
        let fileName: String = formatter.string(from: timestamp) + ".csv"
       // let url = self.getDocumentsDirectory().appendingPathComponent("data.csv")
        let url = self.getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try dataString.write(to: url, atomically: true, encoding: .utf8)
            let input = try String(contentsOf: url)
            print(input)
        } catch {
            print(error.localizedDescription)
        }
        read()
        let destroy = defaults.bool(forKey: "destroyOnSave")
        if destroy {
            // New stuff starts here
            
            visitedLocations.removeAll()
            //    places.removeAll()
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            // 1
            let managedObjectContext = appDelegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try managedObjectContext.executeAndMergeChanges(using: batchDeleteRequest)
            } catch {
                print ("Unexpected Error")
            }
        }
        plotCurrentTrack()
        // ends here
    }
    
    func read() {
        let url = self.getDocumentsDirectory().appendingPathComponent("data.csv")
        
        do {
            let input = try String(contentsOf: url)
            print(input)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func stopPlayer(_ sender: Any) {
        recordButton.isEnabled = true
        pauseButton.isEnabled = true
        stopButton.isEnabled = false
        saveButton.isEnabled = true
        isRecording = false
    }
    
    @IBAction func pausePlayer(_ sender: Any) {
        recordButton.isEnabled = true
        stopButton.isEnabled = true
        pauseButton.isEnabled = false
        saveButton.isEnabled = false
        isRecording = false
    }
    
    @IBAction func startRecording(_ sender: Any) {
        recordButton.isEnabled = false
        stopButton.isEnabled = true
        pauseButton.isEnabled = true
        saveButton.isEnabled = false
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
    
    
    //MARK: Additional stuff for CoreData
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        var places: [NSManagedObject] = []
        // Remove all saved locations
        visitedLocations.removeAll()
        
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Place")
        
        do {
            places = try managedContext.fetch(fetchRequest)
            
            for place in places {
                let longitude = place.value(forKeyPath: "longitude") as? Double
                let latitude = place.value(forKeyPath: "latitude") as? Double
                let elevation = place.value(forKeyPath: "elevation") as? Double
                let horizontalAccuracy = place.value(forKeyPath: "horizontalAccuracy") as? Double
                let verticalAccuracy = place.value(forKeyPath: "verticalAccuracy") as? Double
                let timestamp = (place.value(forKey: "timestamp") as? Date)
                
                let coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                let currentLocation = CLLocation(coordinate: coordinate, altitude: elevation!, horizontalAccuracy:horizontalAccuracy!, verticalAccuracy: verticalAccuracy!,  timestamp: timestamp!)
                
                visitedLocations.append(currentLocation)
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    func saveCurrentLocation( location: CLLocation ) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        // 1
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // 2
        let entity = NSEntityDescription.entity(forEntityName: "Place", in: managedContext)!
        let place = NSManagedObject(entity: entity, insertInto: managedContext)
        
        let elevation = location.altitude as Double
        let timestamp = location.timestamp
        let coordinate = location.coordinate
        let horizontalAccuracy = location.horizontalAccuracy
        let verticalAccuracy = location.verticalAccuracy
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        // 3
        place.setValue(latitude, forKey: "latitude")
        place.setValue(longitude, forKey: "longitude")
        place.setValue(timestamp, forKey: "timestamp")
        place.setValue(elevation, forKey: "elevation")
        place.setValue(verticalAccuracy, forKey: "verticalAccuracy")
        place.setValue(horizontalAccuracy, forKey: "horizontalAccuracy")
        
        // 4
        do {
            try managedContext.save()
            
            //  print("Saved")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

// https://www.avanderlee.com/swift/nsbatchdeleterequest-core-data/
extension NSManagedObjectContext {
    
    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    public func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}


