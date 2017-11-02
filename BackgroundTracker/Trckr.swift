//
//  Trckr.swift
//  Capture
//
//  Created by Rotem Rubnov on 19/08/16.
//  Copyright © 2016 100grams BV. All rights reserved.
//

import UIKit
import CoreLocation

/**
 Trckr tracks the user's location using a combination of:
 - Continuous location updates (while the user is moving)
 - Region monitoring (when the user is stationary)
 - Significant location changes (to sustain background operation)
 - Beacons (detecting vehicle used)
 
 Usage:
 ```
     // start tracking
     Trckr.sharedInstance.trackingEnabled = true
 
     // stop tracking
     Trckr.sharedInstance.trackingEnabled = false
 ```
 
 When using Trckr, you must add the following entries to your app's info.plist:
 - NSMotionUsageDescription
 - NSLocationAlwaysAndWhenInUseUsageDescription
 - NSLocationAlwaysUsageDescription
 - NSLocationWhenInUseUsageDescription
 */

class Trckr: NSObject, CLLocationManagerDelegate {

    // MARK: - Initialization

    static let sharedInstance = Trckr()
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        NotificationCenter.default.addObserver(self, selector:#selector(appDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(appWillResignActive), name: .UIApplicationWillResignActive, object: nil)
     
        Logger.log.verbose("initialized!")
    }
    
    // MARK: - Tracking Locations
    
    let locationManager = CLLocationManager()
    
    // recently locations recorded
    // this buffer is used to check if user is stationary
    var locations = [CLLocation]()
    
    var lastLocation : CLLocation? {
        get {
            return locations.last
        }
    }
    
    internal func clearLocations(olderThan:Date = Date.distantFuture) {
        
        if let loc = self.lastLocation {
            let filtered = locations.filter { $0.timestamp >= olderThan }
            Logger.log.debug("marker: \(olderThan). cleared \(locations.count - filtered.count)/\(locations.count) locations.")
            locations = filtered
            if locations.count == 0 {
                locations.append(loc)
            }
        }
    }

    static let kDefaultLocationUploadInterval = 120 as TimeInterval  // seconds
    //    static let kDefaultLocationUploadInterval = 10 as NSTimeInterval  // seconds
    
    var trackingEnabled : Bool? {
        
        didSet {
            if trackingEnabled==true {
                startTrackingLocation()
                locationManager.startMonitoringSignificantLocationChanges()
            }
            else{
                stopTrackingLocation()
                locationManager.stopMonitoringSignificantLocationChanges()
            }
        }
    }
    
    var locationServicesEnabled : Bool {

        return CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedAlways;
    }

    func startTrackingLocation() {
        
        if CLLocationManager.authorizationStatus() == .notDetermined || CLLocationManager.authorizationStatus() == .restricted {
            Logger.log.verbose("Requesting Authorization...")
            locationManager.requestAlwaysAuthorization()
        }
        else if CLLocationManager.authorizationStatus() != .denied {
            Logger.log.verbose("startTrackingLocation")
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopTrackingLocation() {

        Logger.log.verbose("stopTrackingLocation")

        stopBackgroundTask()
        locationManager.stopUpdatingLocation()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            Logger.log.debug("Asking for location permissions")
        case .denied, .restricted:
            Logger.log.debug("Not allowed")
        default:
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if processNewLocations(locations) {
            
            if let location = Trckr.stationary(locations: self.locations) {
                updateGeofence(name: "CurrentLocation", location: location)
            }
        }
        
        
    }
    
    static let DesiredAccuracy : CLLocationAccuracy = 200
    
    func processNewLocations(_ locs : [CLLocation]) -> Bool {
        
        // filter raw locations, then further process filtered locations
        
        var logMessages = [String]()
        for loc in locs {
            logMessages.append("<wpt lat=\"\(loc.coordinate.latitude)\" lon=\"\(loc.coordinate.longitude)\"><time>\(loc.timestamp)</time></wpt> ( hor. acc \(loc.horizontalAccuracy), speed \(loc.speed))")
            
        }
        Logger.log.debug(logMessages.joined(separator: "\n"))
        
        let filteredLocations = locs.filter {
            let isAccurate = $0.horizontalAccuracy <= Trckr.DesiredAccuracy
            if let lastTimestamp = lastLocation?.timestamp {
                return $0.timestamp > lastTimestamp && isAccurate
            }
            return isAccurate
        }
        
        if filteredLocations.count > 0 {
            locations += filteredLocations
            if let loc = filteredLocations.last {
                checkGeofenceCoverage(location:loc)
            }
            return true
        }
        else{
            Logger.log.info("No new accurate locations received. Discarding.")
            return false
        }
    }
    
    func uploadLastLocation() {
        lastLocationUploadTime = Date()
        
        // TODO
    }
    
    
    // MARK: - Backgrounding
    
    var bgTaskCount = 0
    var bgTaskId : UIBackgroundTaskIdentifier?
    
    var lastLocationUploadTime = NSDate.distantPast
    
    // MARK: - Geofencing
    
    /**
     
     The timestamp of the last ``locationManager:didExitRegion:`` invocation.
     This timestamp is used during pre-checkin phase to ensure that only locations received _after_ this time are considered for stationary detection.
     
     This variable is reset to nil in ``addGeofence:identifier:location:radius:notify``, i.e. when a new geofence region is set.
     */
    var lastTimeDidExitRegion : Date?

    var isSettingGeofencing = false

}




extension Double {
    func format(_ f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}


extension CLLocation {
    
    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        let location = CLLocation(latitude: from.latitude, longitude: from.longitude)
        return self.distance(from: location)
    }
}
