//
//  Track.swift
//  MapMyTrip
//
//  Created by Alex on 13/04/2020.
//  Copyright © 2020 Alex Sykes. All rights reserved.
//

import UIKit
import CoreLocation

class Track: NSObject {
    // MARK: Properties
 var track: [CLLocation]!
     var trackDescription: String
    var date: Date
    
    
    init(trackDescription: String, track: [CLLocation]) {
        self.trackDescription = trackDescription
        self.date = Date()
        self.track = track
    }
}
