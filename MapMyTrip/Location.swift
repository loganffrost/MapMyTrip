//
//  Location.swift
//  MapMyTrip
//
//  Created by Alex on 14/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

import UIKit
import os.log
//import FileManager

class Location: NSObject, NSCoding {
    // MARK: Properties
    var ident: Int!
    var latitude: Double
    var longitude: Double
    var altitude: Double
     var timestamp: Date
    
    // MARK: Archiving paths
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("locations")

    init(ident: Int, latitude: Double, longitude: Double, altitude: Double, timestamp: Date) {
        self.altitude = altitude
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
     //   self.ident = ident
    }
    
    init(latitude: Double, longitude: Double, altitude: Double, timestamp: Date) {
        self.altitude = altitude
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
     //   self.ident = ident
    }
    
    struct PropertyKey {
        static let timestamp = "timestamp"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let altitude = "altitude"
    }

    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(latitude, forKey: PropertyKey.latitude)
        aCoder.encode(timestamp, forKey: PropertyKey.timestamp)
        aCoder.encode(longitude, forKey: PropertyKey.longitude)
        aCoder.encode(altitude, forKey: PropertyKey.altitude)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
      /* guard let ident = aDecoder.decodeObject(forKey: PropertyKey.ident) as? Int else {
            os_log("Unable to decode the ident for a Location object", log: OSLog.default, type: .debug)
            return nil
        } */
        let latitude = aDecoder.decodeDouble(forKey: PropertyKey.latitude)
        let longitude = aDecoder.decodeDouble(forKey: PropertyKey.longitude)
        let altitude = aDecoder.decodeDouble(forKey: PropertyKey.altitude)
        let timestamp = aDecoder.decodeObject(forKey: PropertyKey.timestamp)
        
        self.init(latitude: latitude, longitude: longitude, altitude: altitude, timestamp: timestamp as! Date)
    }
}
