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
            return locations.last
        }
    }
 
    fileprivate func clearLocations(olderThan:Date = Date.distantFuture) {
        
        if let loc = self.lastLocation {
            let filtered = locations.filter { $0.timestamp >= olderThan }
            Logger.log.debug("marker: \(olderThan). cleared \(locations.count - filtered.count)/\(locations.count) locations.")
            locations = filtered
            if locations.count == 0 {
                locations.append(loc)
            }
        }
    }

    // MARK: - Constants

    static let kDefaultTrackingInterval = 10 as TimeInterval  // seconds
//    static let kDefaultTrackingInterval = 3 as NSTimeInterval  // TEST
    static let kDefaultLocationUploadInterval = 120 as TimeInterval  // seconds
//    static let kDefaultLocationUploadInterval = 10 as NSTimeInterval  // seconds
    
    /**
     
     The timestamp of the last ``locationManager:didExitRegion:`` invocation.
     This timestamp is used during pre-checkin phase to ensure that only locations received _after_ this time are considered for stationary detection.
     
     This variable is reset to nil in ``addGeofence:identifier:location:radius:notify``, i.e. when a new geofence region is set.
     */
    var lastTimeDidExitRegion : Date?

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
        
        NotificationCenter.default.addObserver(self, selector:#selector(appDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(appWillResignActive), name: .UIApplicationWillResignActive, object: nil)
     
        Logger.log.verbose("initialized!")
    }
    
    // MARK: - Start/Stop Tracking
    
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
    


    // MARK: - Backgrounding
    
    var bgTaskCount = 0
    var bgTaskId : UIBackgroundTaskIdentifier?
    
    var lastLocationUploadTime = NSDate.distantPast
    
    func startBackgroundTask() {
        
        stopBackgroundTask()
        
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: String(format:"BgTask %ld", bgTaskCount), expirationHandler: { [weak self] in
            if let task = self?.bgTaskId {
                Logger.log.verbose("Background task \(task) expired!")
                self?.updateGeofence(name: "CurrentLocation", location: nil)
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
            
            if let location = LocationTracker.stationary(locations: self.locations) {
                updateGeofence(name: "CurrentLocation", location: location)
            }
        }
        

    }

    static let DesiredAccuracy : CLLocationAccuracy = 200
    var isSettingGeofencing = false

    func processNewLocations(_ locs : [CLLocation]) -> Bool {
        
        // filter raw locations, then further process filtered locations
        
        var logMessages = [String]()
        for loc in locs {
            logMessages.append("<wpt lat=\"\(loc.coordinate.latitude)\" lon=\"\(loc.coordinate.longitude)\"><time>\(loc.timestamp)</time></wpt> ( hor. acc \(loc.horizontalAccuracy), speed \(loc.speed))")
            
        }
        Logger.log.debug(logMessages.joined(separator: "\n"))
        
        let filteredLocations = locs.filter {
            let isAccurate = $0.horizontalAccuracy <= LocationTracker.DesiredAccuracy
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
    
    
}



// MARK: - Is Stationary?

extension LocationTracker {
    
    static let StationaryDistace = 150 as CLLocationDistance    // meters
    static let StationaryInterval = 60 as TimeInterval         // seconds
    static let StationarySpeed = 0.85 as CLLocationSpeed        // meters per second
    
    /**
     
     Determine if an array of locations represents stationary movement at a specific time interval.
     If ``after`` is provided, only locations with timestamp later than ``after`` will be considered.
     
     - parameter locations:   the locations array to evaluate.
     - parameter interval:    locations will be collected based on their timestamp, until ``interval`` is satisfied, and then evaluated based on bounding box.
     - parameter after:       ignore locations before this timestamp. Pass nil to consider all locations (until ``interval`` is met).
     
     - returns: the stationary location from an array, if found
     
     */
    public class func stationary(locations:[CLLocation], interval:TimeInterval = LocationTracker.StationaryInterval, after:Date? = nil) -> CLLocation? {
        
        var lastLocations = [CLLocation]()
        var period = 0 as TimeInterval
        var hasEnoughData = false
        var diagonal = 0 as CLLocationDistance
        guard var prevTimestamp = locations.last?.timestamp else {
            return nil
        }
        
        var validLocations = [CLLocation]()
        if let after = after {
            validLocations = locations.filter { $0.timestamp > after }
        }
        else{
            validLocations = locations
        }
        
        for loc in validLocations.reversed() {
            
            period = period + prevTimestamp.timeIntervalSince(loc.timestamp)
            prevTimestamp = loc.timestamp;
            
            lastLocations.append(loc)
            if lastLocations.count > 1 {
                
                if let bounds = CoordinateBounds(locations:lastLocations) {
                    diagonal = bounds.diagonal
                }
                
                if diagonal > LocationTracker.StationaryDistace {
                    break
                }
                else if period >= interval  {
                    hasEnoughData = true
                    break
                }
            }
        }
        
        var isStationary = false
        var stationaryLocation : CLLocation?
        let averageSpeed : CLLocationSpeed = period > 0 ? diagonal / period : 0
        if hasEnoughData {
            isStationary = averageSpeed < LocationTracker.StationarySpeed
            if  isStationary {
                // most recent accurate location is considered the stationary location
                var markerLoc : CLLocation?
                if let veryAccurateLocation = lastLocations.first(where: {$0.horizontalAccuracy <= 10}) {
                    markerLoc = veryAccurateLocation
                }
                else if let accurateLocation = lastLocations.first(where: {$0.horizontalAccuracy <= 65}) {
                    markerLoc = accurateLocation
                }
                else {
                    markerLoc = lastLocations.first
                }
                
                if markerLoc != nil {
                    // determine the arrival location to the stationary point
                    if let earliest = lastLocations.index(where: { $0.distance(from: markerLoc!) > 5 && $0.timestamp < markerLoc!.timestamp }) {
                        stationaryLocation = lastLocations[earliest]
                    }
                    else {
                        stationaryLocation = markerLoc
                    }
                }
            }
        }
        
        let kph = averageSpeed * 3.6
        if isStationary {
            Logger.log.info("isStationary \(isStationary): average speed =  \(kph.format(".2")) kph, moving distance \(diagonal.format(".2")) in the last \(period.format(".0")) seconds (\(lastLocations.count) locations)")
        }
        else {
            Logger.log.info("isStationary \(isStationary): average speed =  \(kph.format(".2")) kph, moving distance \(diagonal.format(".2")) in the last \(period.format(".0")) seconds (\(lastLocations.count) locations)")
        }
        
        return stationaryLocation
        
    }
    
    func departureLocation(from location : CLLocation) -> CLLocation? {
        return locations.first(where: { $0.distance(from: location) > LocationTracker.StationaryDistace })
    }
    
}



// MARK: - Geofencing

extension LocationTracker {
    
    enum GeofenceNotify : Int {
        case None
        case Entry
        case Exit
    }
    
    @objc enum GeofenceDistance : Int {
        case Short = 50
        case Medium = 150
        case Long = 300
    }
    
    static let kDateLastBackgroundRefreshWarningShown = "LastBackgroundRefreshWarningDate"
    
    fileprivate func updateGeofence (name: String, location: CLLocation?, force : Bool = false, radius : LocationTracker.GeofenceDistance = .Medium) {
        
        guard let loc = location ?? lastLocation else {
            Logger.log.warning("no last location!")
            return
        }
        
        let existing = existingGeofence(name: name) as? CLCircularRegion
        if force || existing == nil || existing?.contains(loc.coordinate) == false {
            addGeofence(name, location:loc, radius:CLLocationDistance(max(loc.horizontalAccuracy, CLLocationAccuracy(radius.rawValue))), notify:.Exit)
        }
        else if let region = existing {
            Logger.log.debug("geofencing exists: \(region.identifier), (\(region.center.latitude),\(region.center.longitude)) \(region.radius)m")
            if isSettingGeofencing == false {
                stopTrackingIfStationary()
            }
        }
    }
    
    fileprivate func addGeofence (_ identifier : String, location: CLLocation, radius : CLLocationDistance, notify : GeofenceNotify) {
        
        let region = CLCircularRegion(center: location.coordinate, radius: radius, identifier: identifier)
        
        region.notifyOnEntry = notify == .Entry;
        region.notifyOnExit = notify == .Exit;
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            if locationServicesEnabled {
                
                // start monitoring
                locationManager.startMonitoring(for: region)
                
                // debug - ask iOS if user currently inside or outside 'region'
                isSettingGeofencing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.locationManager.requestState(for: region)
                }
                
                // ensure background refresh is enabled, otherwise no geofencing or location monitoring
                // will not work while the app is in the background
                if UIApplication.shared.backgroundRefreshStatus != .available {
                    Logger.log.warning("WARNING background refresh status DISABLED - cannot use geofencing or read locations in the background!")
                }
                else{
                    Logger.log.info("Geofencing added: \(identifier), (\(region.center.latitude),\(region.center.longitude)) \(radius)m")
                }
                
                lastTimeDidExitRegion = nil
            }
            else{
                Logger.log.warning("WARNING location services DISABLED - cannot use geofencing!")
            }
        }
        else{
            Logger.log.warning("WARNING region monitoring (geofencing) not available for class \(CLCircularRegion.self) - cannot use geofencing!")
        }
        
    }
    
    
    fileprivate func removeAllGeofencing() {
        Logger.log.info("removeAllGeofencing")
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }
    
    
    fileprivate func removeGeofence(_ identifier:String) {
        
        for region in locationManager.monitoredRegions.filter({ $0.identifier == identifier }) {
            Logger.log.info("remove geofencing \(identifier)")
            locationManager.stopMonitoring(for: region)
        }
    }
    
    fileprivate func existingGeofence(name: String) -> CLRegion? {
        return locationManager.monitoredRegions.filter { $0.identifier == name }.first
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Logger.log.info("locationManager - Geofencing didExitRegion \(region.identifier) center (\((region as! CLCircularRegion).center.latitude), \((region as! CLCircularRegion).center.longitude))")
        if let region = region as? CLCircularRegion {
            handleGeofenceExit(region:region)
        }
    }
    
    /**
     Check if `location` is outside any of the monitored regions and handle accordingly.
     
     This method is useful in case the app is launched to the background with application:didFinishLaunchingWithOptions:
     containing the .location key. In this case, LocationTracker is not yet initialized hence does not receive the
     manager:didExitRegion: call. LocationTracker is then initialized and starts tracking locations. The first accurate
     location received from CoreLocation will call checkGeofenceCoverage and handle the exit event gracefully.
     
     */
    func checkGeofenceCoverage(location:CLLocation) {
        guard lastTimeDidExitRegion == nil else { return }
        for region in locationManager.monitoredRegions {
            if let region = region as? CLCircularRegion,
                region.contains(location.coordinate) == false {
                handleGeofenceExit(region: region)
            }
        }
    }
    
    func handleGeofenceExit(region:CLCircularRegion) {
        lastTimeDidExitRegion = Date()
        trackingEnabled = true;
        maybeStartBackgroundTask()
        
        let coord = region.center
        NotificationsUtility.showLocalNotification(title: "Trip started", message: "(\(coord.latitude), \(coord.longitude))")
    }
    
    func maybeStartBackgroundTask() {
        if  UIApplication.shared.applicationState != .active,
            bgTaskId == UIBackgroundTaskInvalid {
            startBackgroundTask() // allow background location tracking
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Logger.log.error("locationManager - monitoringDidFailForRegion \(region!.identifier) Error: \(error)")
        Logger.log.error("monitored regions (\(locationManager.monitoredRegions.count)): ")
        for region in locationManager.monitoredRegions {
            if let center = (region as? CLCircularRegion)?.center {
                Logger.log.error("\(region.identifier): (\(center.latitude),\(center.longitude))")
            }
        }
        if let region = region {
            removeAllGeofencing()
            updateGeofence(name: region.identifier, location: nil, force: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        let rule = region.notifyOnExit ? "EXIT" : region.notifyOnEntry ? "ENTRY" : ""
        let cr = region as! CLCircularRegion
        Logger.log.debug("Started Geofencing \(rule) for region \(region.identifier) (\(cr.center.latitude),\(cr.center.longitude)) radius \(cr.radius)")
        
        let coord = cr.center
        NotificationsUtility.showLocalNotification(title: "Trip ended", message: "(\(coord.latitude), \(coord.longitude))")
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        
        let rule = region.notifyOnExit ? "EXIT" : region.notifyOnEntry ? "ENTRY" : ""
        var stateName = ""
        var warning : String?
        
        let shouldCorrectGeofencing = isSettingGeofencing
        isSettingGeofencing = false
        
        switch state {
        case .inside:
            stateName = "INSIDE"
            stopTrackingIfStationary()
            
        case .outside:
            stateName = "OUTSIDE"
            if shouldCorrectGeofencing {
                /*
                 We need an EXIT event in order to ensure that, if the app is suspended during an active trip,
                 it will be relaunched to the background with didExitRegion: when EXITING that region.
                 So we must set a geofencing region in which the user is INSIDE.
                 Set a new geofencing trigger with a larger radius to ensure the user is inside it.
                 */
                var distance = GeofenceDistance.Short
                var location : CLLocation? = nil
                if let d = (region as? CLCircularRegion)?.radius {
                    if let failedDistance = GeofenceDistance(rawValue: Int(d)) {
                        switch failedDistance {
                        case .Short:
                            distance = .Medium
                        case .Medium:
                            distance = .Long
                        default:
                            distance = .Long
                            /* The default location for geofencing center is self.lastLocation, which may not be the last true location of the user due to location accuracy filtering
                             (locations with horizontal accuracy > LocationTracker.DesiredAccuracy are ignored).
                             as fallback / last resort, use the last true location recorded by CLLocationManager even if it's not accurate, to ensure geofencing will succeed.
                             */
                            location = locationManager.location
                        }
                        warning = "Will replace \(region.identifier) geofencing from \(failedDistance.rawValue)m to \(distance.rawValue)m, location: \(String(describing: location))"
                    }
                }
                updateGeofence(name: region.identifier, location: nil, force: true, radius: distance)
            }
            
        case .unknown:
            stateName = "UNKNOWN"
            updateGeofence(name: region.identifier, location: nil, force: true)
        }
        
        Logger.log.info("Geofencing state for \(rule) region \(region.identifier) is: \(stateName)")
        if let message = warning {
            Logger.log.info(message)
        }
    }

    func stopTrackingIfStationary() {
        
        if let location = LocationTracker.stationary(locations: self.locations) {
            if NSDate().timeIntervalSince(lastLocationUploadTime) >= LocationTracker.kDefaultLocationUploadInterval {
                uploadLastLocation()
            }
            else {
                trackingEnabled = false
                clearLocations(olderThan: location.timestamp)
            }
        }
    }

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
