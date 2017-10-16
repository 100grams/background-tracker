//
//  Logger.swift
//  Capture
//
//  Created by Rotem Rubnov on 06/09/16.
//  Copyright © 2016 100grams BV. All rights reserved.
//

import UIKit
import XCGLogger
import SSZipArchive

class Logger: NSObject {

    // Create a logger object with no destinations
    static let log = XCGLogger(identifier: "trackerLogger", includeDefaultDestinations: false)
    
    class func start() {
        
        // Create a destination for the system console log (via NSLog)
        let systemLogDestination = AppleSystemLogDestination(owner: Logger.log, identifier: "TrackerLogger.systemLogDestination")
        
        systemLogDestination.outputLevel = .verbose
        systemLogDestination.showLogIdentifier = false
        systemLogDestination.showFunctionName = true
        systemLogDestination.showThreadName = true
        systemLogDestination.showLevel = true
        systemLogDestination.showFileName = true
        systemLogDestination.showLineNumber = true
        systemLogDestination.showDate = true
        
        Logger.log.add(destination: systemLogDestination)
        
        // Create a file log destination
        let fileLogDestination = AutoRotatingFileDestination(owner: Logger.log, writeToFile: Logger.defaultLogFile(), identifier: "TrackerLogger.fileLogDestination", shouldAppend:true)
        
        fileLogDestination.outputLevel = .verbose
        fileLogDestination.showLogIdentifier = false
        fileLogDestination.showFunctionName = true
        fileLogDestination.showThreadName = true
        fileLogDestination.showLevel = true
        fileLogDestination.showFileName = true
        fileLogDestination.showLineNumber = true
        fileLogDestination.showDate = true
        
        // Process this destination in the background
        fileLogDestination.logQueue = XCGLogger.logQueue
        
        Logger.log.add(destination: fileLogDestination)
        
        // Add basic app info, version info etc, to the start of the logs
        Logger.log.logAppDetails()

    }
    
    static let logBaseFileName = "/tracker.log"
    
    static var logDirectory: String {
        let url = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/logs")
        if FileManager.default.fileExists(atPath: url.path) == false {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                Logger.log.error(error)
            }
        }
        return url.path
    }
    
    class func defaultLogFile() -> String {
        return logDirectory + logBaseFileName
    }
    
    class func zippedLogFileName() -> String? {
        let logZipPath = logDirectory + "/log.zip"
        
        do {
            try FileManager.default.removeItem(atPath: logZipPath)
        }
        catch {
            DispatchQueue.main.async {
                Logger.log.error(error)
            }
        }
        
        if SSZipArchive.createZipFile(atPath: logZipPath, withFilesAtPaths:[Logger.defaultLogFile()]) == false {
            DispatchQueue.main.async {
                Logger.log.error("Failed zipping the log file!")
            }
        }
        
        return logZipPath
    }

}
