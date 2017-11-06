//
//  Trckr+background.swift
//  BackgroundTracker
//
//  Created by Rotem Rubnov on 02/11/2017.
//  Copyright © 2017 100grams. All rights reserved.
//

import UIKit

extension Trckr {
 
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
    
    func maybeStartBackgroundTask() {
        if  UIApplication.shared.applicationState != .active,
            (bgTaskId == nil || bgTaskId == UIBackgroundTaskInvalid) {
            startBackgroundTask() // allow background location tracking
        }
        else {
            Logger.log.info("maybeStartBackgroundTask - NO. bgTaskId \(bgTaskId) applicationState \(UIApplication.shared.applicationState)")
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
}

