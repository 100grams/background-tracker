//
//  Trckr+stationary.swift
//  BackgroundTracker
//
//  Created by Rotem Rubnov on 02/11/2017.
//  Copyright © 2017 100grams. All rights reserved.
//

import CoreLocation

extension Trckr {
    
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
    public class func stationary(locations:[CLLocation], interval:TimeInterval = Trckr.StationaryInterval, after:Date? = nil) -> CLLocation? {
        
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
                
                if diagonal > Trckr.StationaryDistace {
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
            isStationary = averageSpeed < Trckr.StationarySpeed
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
    
    func stopTrackingIfStationary() {
        
        if let location = Trckr.stationary(locations: self.locations) {
            if NSDate().timeIntervalSince(lastLocationUploadTime) >= Trckr.kDefaultLocationUploadInterval {
                uploadLastLocation()
            }
            else {
                trackingEnabled = false
                clearLocations(olderThan: location.timestamp)
            }
        }
    }
    
}

