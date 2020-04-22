//
//  ViewController.swift
//  MapMyTrip
//
//  Created by Alex on 12/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

// TODO: Add show tracks option to Settings
// Check for new insta;;ation - no tracks returned etc.
//  1 - Delete tracks from CoreData works when saving
//  2 - Make fileName safe
//  3 - Check filenames for duplicates

import UIKit
import MapKit
import CoreLocation
import CoreData
import CoreFoundation
import CoreServices

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIDocumentPickerDelegate {
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var stopButton: UIBarButtonItem!
    @IBOutlet weak var pauseButton: UIBarButtonItem!
    @IBOutlet weak var recordButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: Properties
    var locationManager: CLLocationManager!
    var userLocation: CLLocation!
    var isRecording: Bool!
    var transportMode: Int!
    var fileFormat: Int!
    var defaults : UserDefaults!
    var recordingThresholds: [Int] = [2,5,10,25,25,50,100,100]
    var recordingThreshold: Int!
    var travelMode: Int!
    var destroyOnSave: Bool!
    var bgLocation: Bool!
    var visitedLocations: [CLLocation]!
    var previousLocation : CLLocation!
    var newLocation : CLLocation!
    var shortFileName: String!
    // var fileExtension: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        mapView.delegate = self
        isRecording = false
        
        statusLabel.text = ""
        
        // Set up array for visted locations
        visitedLocations = [CLLocation]()
        
        // Get user defaults
        defaults = UserDefaults.standard
        travelMode = defaults.integer(forKey:"travelMode")
        if travelMode == nil {
            travelMode = 3
        }
        destroyOnSave = defaults.bool(forKey: "destroyOnSave")
        fileFormat = defaults.integer(forKey: "fileFormat")
        recordingThreshold = recordingThresholds[travelMode]
        
        setupButtons()
        getPermissions()
        setUpMap()
        setupUserTrackingButtonAndScaleView()
        
        // Screen dimming
        // UIScreen.mainScreen.setBrightness(0.5)
        UIApplication.shared.isIdleTimerDisabled = true
        // UIScreen.
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
            //statusLabel.text = "Recording"
            // Check for location existing in locations
            guard let currentLocation = locations.first else {
                return
            }
            
            // Display for status bar
            let lat = String(format:"%.6f", currentLocation.coordinate.latitude)
            let long = String(format:"%.6f", currentLocation.coordinate.longitude)
            let hacc = String(format:"%.0f", currentLocation.horizontalAccuracy)
            let altitude = String(format:"%.0f", currentLocation.altitude)
            let speed = String(format:"%.2f", currentLocation.speed)
            
            
            let status : String = "Recording: \nLat: \(lat) \nLong: \(long) \nAltitude: \(altitude) \nAccuracy: \(hacc) \nSpeed: \(speed)"
            statusLabel.lineBreakMode = .byWordWrapping // notice the 'b' instead of 'B'
            statusLabel.numberOfLines = 0
            statusLabel.text = status
            
            
            // Check for accuracy
            if currentLocation.horizontalAccuracy > 50 {
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
        travelMode = defaults.integer(forKey:"travelMode")
        recordingThreshold = recordingThresholds[travelMode]
    }
    
    // MARK: Functions
    // MARK: File Handling
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        // let public = FileManager
        return paths[0]
    }
    
    // MARK: CSV
    // Prepare visitedLocations for saving as CSV
    func prepareCSVString() -> String{
        // Intiialise data string
        var outputString = ""
        var outputData: [String] = []
        for place in visitedLocations {
            
            let placeString = makeCSVString(place: place)
            outputData.append(placeString)
        }
        outputString = outputData.joined(separator: "\n")
        return outputString
    }
    
    // Make CSV String from a place
    func makeCSVString(place :CLLocation) -> String{
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
    
    // MARK: KML
    // Prepare visitedLocations for saving as KML
    func prepareKMLString() -> String{
        // Intiialise data string
        var outputData: [String] = []
        
        // Intiialise data string
        // Add leading data
        var outputString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        outputString += "<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n<Document>\n<name>"
        outputString += self.shortFileName
        outputString += "</name>\n<description>"
        outputString += "Description"
        outputString += "</description>\n<Style id=\"yellowLineGreenPoly\"><LineStyle><color>7f00ffff</color><width>4</width></LineStyle></Style><Placemark><name>Name of line</name><description>Description of line</description><styleUrl>#yellowLineGreenPoly</styleUrl><LineString><coordinates>"
        
        for place in visitedLocations {
            
            let placeString = makeKMLString(place: place)
            outputData.append(placeString)
        }
        outputString += outputData.joined(separator: "\n")
        
        // Add trailing data
        outputString += "</coordinates></LineString></Placemark></Document></kml>"
        print (outputString)
        return outputString
    }
    
    
    // Make KML String from a place
    func makeKMLString(place :CLLocation) -> String{
        // Sart with an empty string
        // and a CLocation
        let latitude = place.coordinate.latitude
        let longitude = place.coordinate.longitude
        let elevation = place.altitude
        
        // Convert to String data
        let latStr = "\(latitude)"
        let longStr = "\(longitude)"
        let eleStr = "\(elevation)"
        
        var  dataArray: [String] = []
        dataArray.append(longStr)
        dataArray.append(latStr)
        dataArray.append(eleStr)
        
        let dataString = dataArray.joined(separator: ",")
        return dataString
    }
    
    // MARK: GPX
    // Prepare visitedLocations for saving as GPX
    func prepareGPXString() -> String{
        // Intiialise data string
        var outputData: [String] = []
        let now = Date()
        //    let formatter = DateFormatter()
        //     formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: now)
        let trackName = self.shortFileName!
        
        //let timestamp = String(now)
        
        // Intiialise data string
        // Add leading data
        var outputString = "<?xmlversion=\"1.0\"encoding=\"UTF-8\"standalone=\"no\"?>"
        outputString += "\n\n<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" xmlns:gpxx=\"http://www.garmin.com/xmlschemas/GpxExtensions/v3\" xmlns:gpxtpx=\"http://www.garmin.com/xmlschemas/TrackPointExtension/v1\"creator=\"MapMyTrip\"version=\"1.1\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd\">"
        outputString += "\n<metadata>\n\t<link href=\"http://www.alexsykes.com\">\n\t<text>Map My Trip</text>\n\t</link>\n<time>"
        outputString += timestamp
        outputString += "</time>\n</metadata>\n<trk>\n<name>\(trackName)</name>\n<trkseg>\n"
        
        for place in visitedLocations {
            let placeString = makeGPXString(place: place)
            outputData.append(placeString)
        }
        outputString += outputData.joined(separator: "\n")
        outputString += "\n</trkseg>\n</trk>\n</gpx>"
        
        // Print to display
       // print (outputString)

        return outputString
    }
    
    // Make GPX String from a place
    func makeGPXString(place :CLLocation) -> String{
        // Sart with a CLocation
        let latitude = place.coordinate.latitude
        let longitude = place.coordinate.longitude
        let elevation = place.altitude
        
        let time = place.timestamp
        let formatter = ISO8601DateFormatter()
        let timestamp = formatter.string(from: time)
        
        
let dataString = "<trkpt lat=\"\(latitude)\" lon=\"\(longitude)\">\n\t<ele>\(elevation)</ele>\n\t<time>\(timestamp)</time>\n</trkpt>"
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
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .denied || status == .authorizedWhenInUse {
            // present an alert indicating location authorization required
            // and offer to take the user to Settings for the app via
            // UIApplication -openUrl: and UIApplicationOpenSettingsURLString
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
        }
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        bgLocation = defaults.bool(forKey: "bgLocation")
    }
    
    func setUpMap() {
        mapView.mapType = .standard
        mapView.userTrackingMode = MKUserTrackingMode(rawValue: 2)!
        mapView.showsCompass = true
    }
    
    func setupButtons() {
        pauseButton.isEnabled = false
        recordButton.isEnabled = true
        stopButton.isEnabled = false
        saveButton.isEnabled = false
    }
    
    // Render track on map
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5
        // renderer.lineDashPattern = .some([4, 16, 16])
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
    // See - https://www.simplifiedios.net/ios-dialog-box-with-input/
    func showInputDialog() {
        //Creating UIAlertController and
        //Setting title and message for the alert dialog
        let messageText : String!
        if destroyOnSave == true {
            messageText = "This will destroy the current track!"
        } else { messageText = "" }
        
        let alertController = UIAlertController(title: "Enter track name", message: messageText, preferredStyle: .alert)
        
        //the confirm action taking the inputs
        let confirmAction = UIAlertAction(title: "OK", style: .default) { (_) in
            let fileName = alertController.textFields?[0].text
            self.saveTrackData(fileName: fileName!)
        }
        
        //the cancel action doing nothing
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        //adding textfields to our dialog box
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter Track Name here"
        }
        
        //adding the action to dialogbox
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        //finally presenting the dialog box
        self.present(alertController, animated: true, completion: nil)
    }
    
    func onReturnFromSettings(mode: Int) {
        self.travelMode = mode
        self.recordingThreshold = self.recordingThresholds[mode]
        // print("Threshold - \(recordingThreshold)")
    }
    
    @IBAction func printLocations(_ sender: Any) {
        readFromPublic()
    }
    
    @IBAction func savePlaces (_ sender: Any) {
        showInputDialog()
    }
    
    func readFromPublic () {
        
        // open a document picker, select a file
        // documentTypes see - https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html#//apple_ref/doc/uid/TP40009259-SW1
        
        let importFileMenu = UIDocumentPickerViewController(documentTypes: ["public.text"],
                                                            in: UIDocumentPickerMode.import)
        importFileMenu.delegate = self
        if #available(iOS 13.0, *) {
            print("File iOS 13+")
            importFileMenu.directoryURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.alexsykes.MapMyTrip")!
        } else {
            // Fallback on earlier versions
            print("File iOS <=12")
        }
        importFileMenu.modalPresentationStyle = .formSheet
        
        self.present(importFileMenu, animated: true, completion: nil)
        
    }
    
    /*
     Included for demonstration of file picker
     
     func saveTrackDataAlt () {
     
     let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.text"],  in: .open)
     documentPicker.delegate = self
     documentPicker.shouldShowFileExtensions = true
     documentPicker.allowsMultipleSelection = true
     present(documentPicker, animated: true) {
     print("done presenting")
     }
     }
     
     
     func documentPicker(_ controller: UIDocumentPickerViewController,
     didPickDocumentsAt urls: [URL]) {
     
     let dataString : String = prepareWriteString()
     
     let url = urls[0]
     
     let directory = url.deletingLastPathComponent()
     let filename = url.lastPathComponent
     print (filename)
     // let dataString = "Again"
     do {
     try dataString.write(to: url, atomically: true, encoding: .utf8)
     let input = try String(contentsOf: url)
     print(input)
     } catch {
     print(error.localizedDescription)
     }
     }
     */
    
    func saveTrackData(fileName: String) {
        // Get filename then add time stamp
        self.shortFileName = fileName
        var fileName = fileName
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "_dd_MM_yy_HH_mm"
        let timeString = formatter.string(from: timestamp)
        fileName += timeString
        
        fileFormat = defaults.integer(forKey: "fileFormat")
        var dataString: String!
        
        // Always write CSV data
        dataString  = prepareCSVString()
        var fileExtension = ".csv"
        writeOutputString(dataString: dataString, fileName: fileName, fileExtension: fileExtension)
        
        // Get data - depending on file format
        switch fileFormat {

        case 1:
            // KML
            dataString = prepareKMLString()
            fileExtension  = ".kml"
            // Create fileName for writing
            writeOutputString(dataString: dataString, fileName: fileName, fileExtension: fileExtension)
        case 2:
            dataString  = prepareGPXString()
            fileExtension  = ".gpx"
            // Create fileName for writing
            writeOutputString(dataString: dataString, fileName: fileName, fileExtension: fileExtension)
        default:
            print ("CSV file - not written")
            // Do not write file
        }
        
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
    
    func writeOutputString (dataString: String, fileName: String, fileExtension: String) {
        let longFileName = fileName + fileExtension
        
        let url = self.getDocumentsDirectory().appendingPathComponent(longFileName)
        
        do {
            try dataString.write(to: url, atomically: true, encoding: .utf8)
            let input = try String(contentsOf: url)
            print(input)
        } catch {
            print(error.localizedDescription)
        }
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
        pauseButton.isEnabled = false
        stopButton.isEnabled = false
        saveButton.isEnabled = true
        isRecording = false
        statusLabel.text = "Stopped"
    }
    
    @IBAction func pausePlayer(_ sender: Any) {
        recordButton.isEnabled = true
        stopButton.isEnabled = true
        pauseButton.isEnabled = false
        saveButton.isEnabled = false
        isRecording = false
        statusLabel.text = "Paused"
    }
    
    @IBAction func startRecording(_ sender: Any) {
        recordButton.isEnabled = false
        stopButton.isEnabled = true
        pauseButton.isEnabled = true
        saveButton.isEnabled = false
        isRecording = true
        statusLabel.text = "Recording"
        
        // Check that threshold is up to date
        self.recordingThreshold = self.recordingThresholds[travelMode]
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


