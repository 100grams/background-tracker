//
//  Trckr+geofence.swift
//  BackgroundTracker
//
//  Created by Rotem Rubnov on 02/11/2017.
//  Copyright © 2017 100grams. All rights reserved.
//

import UIKit
import CoreLocation

extension Trckr {
    
    enum RegionNotify : Int {
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
    
    internal func updateGeofence (name: String, location: CLLocation?, force : Bool = false, radius : Trckr.GeofenceDistance = .Medium) {
        
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
    
    internal func addGeofence (_ identifier : String, location: CLLocation, radius : CLLocationDistance, notify : RegionNotify) {
        
        let region = CLCircularRegion(center: location.coordinate, radius: radius, identifier: identifier)
        
        if startMonitoring(region: region, notify: notify) == true {
            isSettingGeofencing = true
            Logger.log.info("Adding geofencing: \(identifier), (\(region.center.latitude),\(region.center.longitude)) \(radius)m")
        }
        
    }

    internal func startMonitoring(region : CLRegion, notify : RegionNotify) -> Bool {
        
        region.notifyOnEntry = notify == .Entry;
        region.notifyOnExit = notify == .Exit;
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            if locationServicesEnabled {
                
                // start monitoring
                locationManager.startMonitoring(for: region)
                
                // ask iOS if user currently inside or outside 'region'
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.locationManager.requestState(for: region)
                }
                
                // ensure background refresh is enabled, otherwise no geofencing or location monitoring
                // will not work while the app is in the background
                if UIApplication.shared.backgroundRefreshStatus != .available {
                    Logger.log.warning("WARNING background refresh status DISABLED - cannot monitor regions in the background!")
                    return false
                }
                lastTimeDidExitRegion = nil
                return true
            }
            else{
                Logger.log.warning("WARNING location services DISABLED - cannot use region monitoring!")
                return false
            }
        }
        else{
            Logger.log.warning("WARNING region monitoring not available for class \(String(describing: type(of: region)))")
            return false
        }
    }
    
    internal func removeGeofence(_ identifier:String) {
        
        for region in locationManager.monitoredRegions.filter({ $0.identifier == identifier }) {
            Logger.log.info("remove geofencing \(identifier)")
            locationManager.stopMonitoring(for: region)
        }
    }
    
    internal func existingGeofence(name: String) -> CLRegion? {
        return locationManager.monitoredRegions.filter { $0.identifier == name }.first
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            Logger.log.info("locationManager - Geofencing didExitRegion \(region.identifier) center (\(region.center.latitude), \(region.center.longitude))")
            handleGeofenceExit(region:region)
        }
        else if let region = region as? CLBeaconRegion {
            Logger.log.info("locationManager - Beacon didExitRegion \(region.identifier) (\(String(describing: region.major))/\(String(describing: region.minor)))")
            handleBeaconExit(region:region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLBeaconRegion {
            Logger.log.info("locationManager - Beacon didEnterRegion \(region.identifier) (\(String(describing: region.major))/\(String(describing: region.minor)))")
            handleBeaconEntry(region:region)
        }
    }
    /**
     Check if `location` is outside any of the monitored regions and handle accordingly.
     
     This method is useful in case the app is launched to the background with application:didFinishLaunchingWithOptions:
     containing the .location key. In this case, Trckr is not yet initialized hence does not receive the
     manager:didExitRegion: call. Trckr is then initialized and starts tracking locations. The first accurate
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
        Logger.log.debug("Trip started (\(coord.latitude), \(coord.longitude))")
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
            removeGeofence(region.identifier)
            updateGeofence(name: region.identifier, location: nil, force: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        let rule = region.notifyOnExit ? "EXIT" : region.notifyOnEntry ? "ENTRY" : ""
        let cr = region as! CLCircularRegion
        Logger.log.debug("Started Geofencing \(rule) for region \(region.identifier) (\(cr.center.latitude),\(cr.center.longitude)) radius \(cr.radius)")
        
        // DEBUG: show notification
        if let _ = Trckr.stationary(locations: self.locations) {
            let coord = cr.center
            NotificationsUtility.showLocalNotification(title: "Trip ended", message: "(\(coord.latitude), \(coord.longitude))")
            Logger.log.debug("Trip ended (\(coord.latitude), \(coord.longitude))")
        }
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
            if type(of: region) == type(of: CLCircularRegion.self) {
                stopTrackingIfStationary()
            }
            
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
                             (locations with horizontal accuracy > Trckr.DesiredAccuracy are ignored).
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
            if type(of: region) == type(of: CLCircularRegion.self) {
                updateGeofence(name: region.identifier, location: nil, force: true)
            }
        }
        
        Logger.log.info("Geofencing state for \(rule) region \(region.identifier) is: \(stateName)")
        if let message = warning {
            Logger.log.info(message)
        }
    }
        
}
