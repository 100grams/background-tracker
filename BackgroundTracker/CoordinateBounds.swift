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

    var northEast : CLLocationCoordinate2D?
    var southWest : CLLocationCoordinate2D?
    
    init(withNorthEast ne:CLLocationCoordinate2D, sw:CLLocationCoordinate2D) {
     
        super.init()
        northEast = ne
        southWest = sw
    }
    
    open class func boundsWithLocations(_ locations:Array<CLLocation>) -> CoordinateBounds? {

        if locations.count == 0 {
            return nil
        }
        
        let loc = locations.first!
        var minLat = loc.coordinate.latitude
        var minLon = loc.coordinate.longitude
        var maxLat = loc.coordinate.latitude
        var maxLon = loc.coordinate.longitude
        
        for loc in locations {
            minLat = min(loc.coordinate.latitude, minLat)
            minLon = min(loc.coordinate.longitude, minLon)
            maxLat = max(loc.coordinate.latitude, maxLat)
            maxLon = max(loc.coordinate.longitude, maxLon)
        }
        
        return CoordinateBounds(withNorthEast: CLLocationCoordinate2DMake(maxLat, minLon), sw: CLLocationCoordinate2DMake(minLat, maxLon))
    }
    
    open var diagonal : CLLocationDistance {
        get {
            let ne = CLLocation(latitude: northEast!.latitude, longitude: northEast!.longitude)
            let sw = CLLocation(latitude: southWest!.latitude, longitude: southWest!.longitude)
            return ne.distance(from: sw)
        }
    }
    
    class func degreeToRadian(_ angle:CLLocationDegrees) -> Double{
        
        return (  (Double(angle)) / 180.0 * Double.pi  )
        
    }
    
    class func radianToDegree(_ radian:Double) -> CLLocationDegrees{
        
        return CLLocationDegrees(  radian * 180.0 / Double.pi  )
        
    }
    
    open var center : CLLocation {
        get {
            if northEast != nil {
                if southWest != nil {
                    var x = 0.0 as Double
                    var y = 0.0 as Double
                    var z = 0.0 as Double
                    
                    let listCoords = [northEast, southWest]
                    for coordinate in listCoords{
                        
                        let lat = CoordinateBounds.degreeToRadian(coordinate!.latitude)
                        let lon = CoordinateBounds.degreeToRadian(coordinate!.longitude)
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
                return CLLocation(latitude: northEast!.latitude, longitude: northEast!.longitude)
            }
            return CLLocation(latitude: southWest!.latitude, longitude: southWest!.longitude)
            
        }
        
    }
    
}
