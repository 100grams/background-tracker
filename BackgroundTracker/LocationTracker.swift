//
//  LocationTracker.swift
//  Capture
//
//  Created by Rotem Rubnov on 19/08/16.
//  Copyright © 2016 100grams BV. All rights reserved.
//

import UIKit
import CoreLocation

class LocationTracker: NSObject, CLLocationManagerDelegate {

    static let sharedInstance = LocationTracker()
    
    let locationManager = CLLocationManager()

    // recently locations recorded
    // this buffer is used to check if user is stationary
    var locations = [CLLocation]()
    
    var lastLocation : CLLocation? {
        get {
            if locations.count > 0 {
                return locations.last!
            }
            return nil
        }
    }
 
    // MARK: - Constants

    static let kDefaultTrackingInterval = 10 as TimeInterval  // seconds
//    static let kDefaultTrackingInterval = 3 as NSTimeInterval  // TEST
    static let kDefaultLocationUploadInterval = 120 as TimeInterval  // seconds
//    static let kDefaultLocationUploadInterval = 10 as NSTimeInterval  // seconds
    
    static let StationaryDistace = 150 as CLLocationDistance    // meters
    static let StationaryInterval = 180 as TimeInterval         // seconds
//    static let StationaryInterval = 10 as NSTimeInterval        // TEST
    static let StationarySpeed = 0.85 as CLLocationSpeed        // meters per second

    // MARK: - Initialization

    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        /*
         "Lastly, I will tell you that the exact behavior of background location
         updates varies significantly depending on what other monitoring APIs are
         active.  If you experiment with our other location APIs (for example,
         significant location updates), I believe you’ll discover that
         startUpdatingLocation will allow continual monitoring in situations where it
         previously did not."
                        
                                             Kevin Elliott
                                             DTS Engineer
                                             kevin_elliott@apple.com
         
         */
        locationManager.startMonitoringSignificantLocationChanges()

        
        NotificationCenter.default.addObserver(self, selector:#selector(appDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(appWillResignActive), name: .UIApplicationWillResignActive, object: nil)
     
        Logger.log.verbose("initialized!")
    }
    
    // MARK: - Tracking Location
    
    var trackingEnabled : Bool? {
        
        didSet {
            if trackingEnabled==true {
                startTrackingLocation()
            }
            else{
                stopTrackingLocation()
                // clean locations array, keeping only the last location
                let loc = locations.last
                locations.removeAll()
                if loc != nil {
                    locations.append(loc!)
                }
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
            Logger.log.verbose("")
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopTrackingLocation() {

        Logger.log.verbose("")

        stopBackgroundTask()
        locationManager.stopUpdatingLocation()
    }
    


    // MARK: - Backgrounding
    
    var bgTaskCount = 0
    var bgTaskId : UIBackgroundTaskIdentifier?
    
    var lastLocationUploadTime = NSDate.distantPast
    
    func startBackgroundTask() {
        
        stopBackgroundTask()
        
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: String(format:"BgTask %ld", bgTaskCount), expirationHandler: { [weak self] in
            if let task = self?.bgTaskId {
                Logger.log.verbose("Background task \(task) expired!")
            }
            self?.stopBackgroundTask()
        })
        
        if bgTaskId == UIBackgroundTaskInvalid {
            Logger.log.debug("ERROR: received UIBackgroundTaskInvalid when trying to start background task. Will not record locations in background!")
        }
        else{
            bgTaskCount += 1
            if let task = self.bgTaskId {
                Logger.log.debug("Starting background task \(task). Background time remaining: \(UIApplication.shared.backgroundTimeRemaining)")
            }
            
        }
    }



    func stopBackgroundTask() {
        
        if bgTaskId != nil && bgTaskId != UIBackgroundTaskInvalid {
            Logger.log.debug("Stopping background task \(self.bgTaskId!)");
            UIApplication.shared.endBackgroundTask(bgTaskId!)
            bgTaskId = UIBackgroundTaskInvalid
        }
        
    }

    func appWillResignActive() {
        
        Logger.log.debug("On Background now!!!")
        
        if trackingEnabled == true {

            startBackgroundTask()
        }
        else{
            trackingEnabled = false;
        }
        
    }
    
    func appDidBecomeActive() {
    
        Logger.log.verbose("On Foreground now!!!");
        
        stopBackgroundTask()
        trackingEnabled = true

    }
    
    
    // MARK: - CLLocationManagerDelegate

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

            if isStationary {
                // stop location tracking
                trackingEnabled = false
                updateGeofencingForCurrentLocationIfNeeded(force: true)
            }
            else {
                updateGeofencingForCurrentLocationIfNeeded(force: false)
                maybeStartBackgroundTask()
            }
        }
        
        if NSDate().timeIntervalSince(lastLocationUploadTime) >= LocationTracker.kDefaultLocationUploadInterval {
            uploadLastLocation()
        }

    }

    static let MinAccuracy : CLLocationAccuracy = 100
    
    func processNewLocations(_ locs : [CLLocation]) -> Bool {
        
        var logMessages = [String]()
        for loc in locs {
            logMessages.append("<wpt lat=\"\(loc.coordinate.latitude)\" lon=\"\(loc.coordinate.longitude)\"><time>\(loc.timestamp)</time></wpt> ( hor. acc \(loc.horizontalAccuracy), speed \(loc.speed))")
            
        }
        Logger.log.debug(logMessages.joined(separator: "\n"))

        let filteredLocations = locs.filter { $0.horizontalAccuracy <= LocationTracker.MinAccuracy }
        
        if filteredLocations.count > 0 {
            locations += filteredLocations
            return true
        }
        else{
            Logger.log.warning("No accurate locations received. Discarding.")
            return false
        }
    }
    
    func uploadLastLocation() {
        lastLocationUploadTime = Date()
        
        // TODO
    }
    
    var isStationary : Bool {
 
        get {
            var isStationary = true
            
            var lastLocations = [CLLocation]()
            var period = 0 as TimeInterval
            var hasEnoughData = false
            var diagonal = 0 as CLLocationDistance
            guard var prevTimestamp = locations.last?.timestamp else {
                return true
            }
            
            for loc in locations.reversed() {
                
                period = period + prevTimestamp.timeIntervalSince(loc.timestamp)
                prevTimestamp = loc.timestamp;
                
                lastLocations.append(loc)
                if lastLocations.count > 1 {
                    
                    diagonal = CoordinateBounds.boundsWithLocations(lastLocations)!.diagonal
                    if diagonal > LocationTracker.StationaryDistace {
                        break
                    }
                    else if period >= LocationTracker.StationaryInterval  {
                        hasEnoughData = true
                        break
                    }
                }
            }
            
            let averageSpeed : CLLocationSpeed = period > 0 ? diagonal / period : 0
            if hasEnoughData == false {
                isStationary = false
            }
            else{
                isStationary = averageSpeed < LocationTracker.StationarySpeed
            }
            
            let kph = averageSpeed * 3.6
            Logger.log.verbose("\(isStationary): average speed =  \(kph.format(".2")) kph, moving distance \(diagonal.format(".2")) in the last \(period.format(".0")) seconds (\(lastLocations.count) locations)")
            
            return isStationary;
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Logger.log.verbose("locationManager - Geofencing didExitRegion \(region.identifier) center (\((region as! CLCircularRegion).center.latitude), \((region as! CLCircularRegion).center.longitude))")
        trackingEnabled = true;
        removeAllGeofencing()
        maybeStartBackgroundTask()
    }
    
    func maybeStartBackgroundTask() {
        if  UIApplication.shared.applicationState != .active,
            bgTaskId == nil || bgTaskId == UIBackgroundTaskInvalid {
            startBackgroundTask() // allow background location tracking
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Logger.log.verbose("locationManager - monitoringDidFailForRegion \(region!.identifier) Error: \(error)")
        updateGeofencingForCurrentLocationIfNeeded(force: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        let rule = region.notifyOnExit ? "EXIT" : region.notifyOnEntry ? "ENTRY" : ""
        let cr = region as! CLCircularRegion
        Logger.log.verbose("Started Geofencing \(rule) for region \(region.identifier) (\(cr.center.latitude),\(cr.center.longitude)) radius \(cr.radius)")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        let rule = region.notifyOnExit ? "EXIT" : region.notifyOnEntry ? "ENTRY" : ""
        var stateName = ""
        var warning : String?
        switch state {
        case .inside:
            stateName = "INSIDE"
        case .outside:
            stateName = "OUTSIDE"
            if region.notifyOnExit == true &&
                region.identifier == "CurrentLocation" {
                // We need "CurrentLocation" EXIT event in order to keep the app
                // running in the background via didExitRegion callbacks.
                // However, we are already OUTSIDE of the monitored region for "CurrentLocation"
                // hence we will never be notified about EXITING that region, and the app will not
                // continue tracking locations. In this case we must update the geofencing
                // to update the "CurrentLocation" region.
                var distance = GeofencDistance.Short
                if let d = (region as? CLCircularRegion)?.radius {
                    if let failedDistance = GeofencDistance(rawValue: d) {
                        switch failedDistance {
                        case .Short:
                            distance = .Medium
                        default:
                            distance = .Long
                        }
                        warning = "Replaced geofencing for \(failedDistance) with \(distance)"
                    }
                }
                updateGeofencingForCurrentLocationIfNeeded(force: true, radius: distance)
            }
        case .unknown:
            stateName = "UNKNOWN"
            if region.identifier == "CurrentLocation" {
                removeAllGeofencing()
                updateGeofencingForCurrentLocationIfNeeded(force: false)
            }
        }
        
        Logger.log.verbose("Geofencing state for \(rule) region \(region.identifier) is: \(stateName)")
        if let message = warning {
            Logger.log.warning(message)
        }
    }

    // MARK: - Geofencing
    
    enum GeofenceNotify : Int {
        case None
        case Entry
        case Exit
    }

    var geofenceLocations = [String:CLLocation]()
    
    enum GeofencDistance : CLLocationDistance {
        case Short = 50
        case Medium = 150
        case Long = 300
    }
    
    static let kDateLastBackgroundRefreshWarningShown = "LastBackgroundRefreshWarningDate"
    
    func updateGeofencingForCurrentLocationIfNeeded (force : Bool, radius : LocationTracker.GeofencDistance = .Short) {
        
        guard let location = locations.last else {
            Logger.log.warning("no location found!")
            return
        }

        let geofenceCurrent = geofenceLocations["CurrentLocation"]

        if force || geofenceCurrent == nil || (geofenceCurrent?.distance(from: location) ?? 0) > 150 {
    
            // user moved since last "CurrentLocation" geofencing
            addGeofencingWithName("CurrentLocation", location:location, radius:radius.rawValue, notify:.Exit)
        
        }
    }
    
    func addGeofencingWithName (_ identifier : String, location: CLLocation, radius : CLLocationDistance, notify : GeofenceNotify) {
    
        let region = CLCircularRegion(center: location.coordinate, radius: radius, identifier: identifier)
        
        region.notifyOnEntry = notify == .Entry;
        region.notifyOnExit = notify == .Exit;
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            if locationServicesEnabled {
                
                // start monitoring
                locationManager.startMonitoring(for: region)
                
                // debug - ask iOS if user currently inside or outside 'region'
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.locationManager.requestState(for: region)
                }
                
                // ensure background refresh is enabled, otherwise no geofencing or location monitoring
                // will not work while the app is in the background
                if UIApplication.shared.backgroundRefreshStatus != .available {
                    Logger.log.warning("WARNING background refresh status DISABLED - cannot use geofencing or read locations in the background!")
                }
                else{
                    Logger.log.verbose("Geofencing for \(identifier) set (\(region.center.latitude),\(region.center.longitude)) @\(radius)m")
                    self.geofenceLocations[identifier] = location;
                }
            }
            else{
                Logger.log.warning("WARNING location services DISABLED - cannot use geofencing!")
            }
        }
        else{
            Logger.log.warning("WARNING region monitoring (geofencing) not available for class \(CLCircularRegion.self) - cannot use geofencing!")
        }

    }
    
    
    private func removeAllGeofencing() {
        Logger.log.verbose("");
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        geofenceLocations.removeAll()
    }

    

}


extension Double {
    func format(_ f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

