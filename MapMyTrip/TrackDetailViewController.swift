//
//  TrackDetailViewController.swift
//  MapMyTrip
//
//  Created by Alex on 16/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation
import MapKit


class TrackDetailViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate  {
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Properties
    var file: URL?
    var fileData: [String]!
    var track: [CLLocation]!
    var visitedPoints: [MKPointAnnotation]!
    var locationManager: CLLocationManager!
    var userLocation: CLLocation!
    var polyline: MKPolyline!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initial setup
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        mapView.delegate = self
        
        // read data from file
        fileData = readFile(url: file!)
        let fileName = file?.lastPathComponent
        
        // shortFileName is text name
        let shortfilename = String(fileName![..<fileName!.firstIndex(of: ".")!])
        
        print (shortfilename)
        track = convertToCLLocation(fileData: fileData)
        
        // Plot track and points
        plotCurrentTrack()
        plotPoints()
        
        /* Following execution, the following are set
         file - original URL
         fileData - String array from file
         track - CLLocation array for display
         visitedPoints - array of Annotations
         fileName - original filename
         */
    }
    
    // Plots track loaded from visitedLocations array
    func plotCurrentTrack() {
        // if (visitedLocations.last as CLLocation?) != nil {
        var coordinates = track.map({(location: CLLocation) -> CLLocationCoordinate2D in return location.coordinate})
        polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        //  }
    }
    
    // Plot array of markers
    func plotPoints () {
        visitedPoints = []
        let count = track.count
        var index = 0
        print("Points in track: \(count)")
    //    self.mapView.removeAnnotations(visitedPoints)
        
        for point in track {
            let annotation = MKPointAnnotation()
            annotation.title = "\(index)"
            annotation.subtitle = "Click to delete"
            annotation.coordinate = point.coordinate
            // annotation.description = String(index)
            
            visitedPoints.append(annotation)
            
            index += 1
            
            // self.mapView.addAnnotation(annotation)
            self.mapView.showAnnotations(visitedPoints, animated: true)
        }
    }
    
    // Modifications for adding action etc
    // See - https://www.techotopia.com/index.php/Working_with_MapKit_Local_Search_in_iOS_8_and_Swift
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation)
        -> MKAnnotationView? {
            
            let identifier = "marker"
            var view: MKMarkerAnnotationView
            
            //        if let dequeuedView = mapView.dequeueReusableAnnotationView(
            //                                 withIdentifier: identifier)
            //                                     as? MKMarkerAnnotationView {
            //            dequeuedView.annotation = annotation
            //            view = dequeuedView
            //        } else {
            view =
                MKMarkerAnnotationView(annotation: annotation,
                                       reuseIdentifier: identifier)
            //  view.markerTintColor = UIColor.blue
            //   view.glyphText = "Here"
            
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .close)
            //  }
            return view
    }
    
    // MARK: Marker delete
    // Action added to marker
    func mapView(_: MKMapView, annotationView:
        MKAnnotationView, calloutAccessoryControlTapped: UIControl) {
        //id = calloutAccessoryControlTapped.
        mapView.removeOverlay(polyline)
        let annotation = annotationView.annotation
        let id :String = (annotation?.title)!!
        let index :Int = Int(id)!
        track.remove(at: index)
        visitedPoints.remove(at: index)
       
        self.mapView.removeAnnotations(self.mapView.annotations)
  //      self.mapView.removeAnnotation(annotationView)
        plotPoints()
        plotCurrentTrack()
        mapView.addAnnotations(visitedPoints)
        print("Plotted")
    }
    
    
    // Centre map on start of track
    func centreMap(location: CLLocation){
        let region_radius = 1000
        let region = MKCoordinateRegion(center: location.coordinate,latitudinalMeters: CLLocationDistance(region_radius), longitudinalMeters: CLLocationDistance(region_radius))
        mapView.setRegion(region, animated: true)
        
    }
    
    // Render track on map
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5
        // renderer.lineDashPattern = .some([4, 16, 16])
        return renderer
    }
    
    func printTrackData () {
        for point in track {
            let loc = point.coordinate
            let lat = loc.latitude
            let long = loc.longitude
            let hacc = point.horizontalAccuracy
            let vacc = point.horizontalAccuracy
            let elev = point.altitude
            let timestamp = point.timestamp
            print("\(lat) : \(long) : \(hacc) : \(vacc) : \(elev) : \(timestamp)")
        }
    }
    func  convertToCLLocation(fileData :[String]) -> [CLLocation] {
        var theLocations: [CLLocation] = []
        var theLocation: CLLocation!
        var coordinate: CLLocationCoordinate2D
        var elevation: Double!
        var latitude: Double!
        var longitude: Double!
        var hacc: Double!
        var vacc: Double!
        var timestampS: String!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var values :[String] = []
        for line in fileData {
            values  = line.components(separatedBy: ",")
            latitude = Double(values[0])
            longitude = Double(values[1])
            hacc = Double(values[2])
            vacc = Double(values[3])
            elevation = Double(values[4])
            timestampS = values[5]
            
            let date = formatter.date(from: timestampS)
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            theLocation = CLLocation(coordinate: coordinate, altitude: elevation, horizontalAccuracy: hacc, verticalAccuracy: vacc, timestamp: date ?? Date())
            theLocations.append(theLocation)
        }
        return theLocations
    }
    
    // Read trackdata from storage
    // Return array of Strings
    func readFile(url :URL) -> [String] {
        var points:[String] = []
        let path = url.path
        let fileContents = FileManager.default.contents(atPath: path)
        let fileContentsAsString = String(bytes: fileContents!, encoding: .utf8)
        
        // Split lines then append to array
        let lines = fileContentsAsString!.split(separator: "\n")
        for line in lines {
            points.append(String(line))
        }
        return points
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    /*
    func traitCollectionDidChange(previousTraitCollection :UITraitCollection ) {
        super.traitCollectionDidChange(previousTraitCollection: self)
        if @available(iOS 13.0, *) {
            if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
                for (id<MKAnnotation> annotation in self.mapView.annotations) {
                    [self.mapView removeAnnotation:annotation];
                    [self.mapView addAnnotation:annotation];
                    [self mapView:self.mapView viewForAnnotation:annotation];
                }
            }
        }
    }
    */
}
