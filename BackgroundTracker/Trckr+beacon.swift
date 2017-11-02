//
//  Trckr+beacon.swift
//  BackgroundTracker
//
//  Created by Rotem Rubnov on 02/11/2017.
//  Copyright © 2017 100grams. All rights reserved.
//

import CoreLocation

extension Trckr {
    
    /**
     Start monitoring a beacon region
     
     - parameter identifier: A unique identifier to associate with the returned region object. You use this identifier to differentiate regions within your application. This value must not be nil.
     
     - parameter proximityUUID: The unique ID of the beacons being targeted. This value must not be nil.
     
     - parameter notify: the type of notification to received, i.e. Entry, Exit or both.
     */
    internal func addBeacon (_ identifier : String, proximityUUID: UUID, notify : RegionNotify) {
    
        let region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: identifier)
        
        if startMonitoring(region: region, notify: notify) {
            Logger.log.info("Beacon added: \(identifier), UUID \(region.proximityUUID), \(String(describing: region.major))/\(String(describing: region.minor))")
        }
    }

}
