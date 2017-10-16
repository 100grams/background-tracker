//
//  CoordinateBounds.swift
//  Capture
//
//  Created by Rotem Rubnov on 22/08/16.
//  Copyright © 2016 100grams BV. All rights reserved.
//

import UIKit
import CoreLocation

open class CoordinateBounds: NSObject {

    var northEast : CLLocationCoordinate2D
    var southWest : CLLocationCoordinate2D
    
    init(withNorthEast ne:CLLocationCoordinate2D, sw:CLLocationCoordinate2D) {
        
        northEast = ne
        southWest = sw
        super.init()
    }
    
    init?(locations:Array<CLLocation>) {
        
        if locations.count > 0 {
            
            let maxLat = locations.map { $0.coordinate.latitude }.max()
            let minLat = locations.map { $0.coordinate.latitude }.min()
            let maxLon = locations.map { $0.coordinate.longitude }.max()
            let minLon = locations.map { $0.coordinate.longitude }.min()
            
            northEast = CLLocationCoordinate2DMake(maxLat!, minLon!)
            southWest = CLLocationCoordinate2DMake(minLat!, maxLon!)
            
            super.init()
        }
        else{
            return nil
        }
        
    }
    
    open var diagonal : CLLocationDistance {
        get {
            let ne = CLLocation(latitude: northEast.latitude, longitude: northEast.longitude)
            let sw = CLLocation(latitude: southWest.latitude, longitude: southWest.longitude)
            return ne.distance(from: sw)
        }
    }
    
    class func degreeToRadian(_ angle:CLLocationDegrees) -> Double{
        
        return (  (Double(angle)) / 180.0 * Double.pi  )
        
    }
    
    class func radianToDegree(_ radian:Double) -> CLLocationDegrees{
        
        return CLLocationDegrees(  radian * 180.0 / Double.pi  )
        
    }
    
    /*
     center (middle) coordinate of the area reflected by bounds
     */
    open var center : CLLocation {
        get {
            var x = 0.0 as Double
            var y = 0.0 as Double
            var z = 0.0 as Double
            
            let listCoords = [northEast, southWest]
            for coordinate in listCoords{
                
                let lat = CoordinateBounds.degreeToRadian(coordinate.latitude)
                let lon = CoordinateBounds.degreeToRadian(coordinate.longitude)
                x = x + cos(lat) * cos(lon)
                y = y + cos(lat) * sin(lon);
                z = z + sin(lat);
            }
            
            x = x/Double(listCoords.count)
            y = y/Double(listCoords.count)
            z = z/Double(listCoords.count)
            
            let resultLon = atan2(y, x)
            let resultHyp = sqrt(x*x+y*y)
            let resultLat = atan2(z, resultHyp)
            
            let newLat = CoordinateBounds.radianToDegree(resultLat)
            let newLon = CoordinateBounds.radianToDegree(resultLon)
            
            return CLLocation(latitude: newLat, longitude: newLon)
        }
        
    }    
}
