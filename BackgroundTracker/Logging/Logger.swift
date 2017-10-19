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
import FirebaseStorage

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
        let fileLogDestination = AutoRotatingFileDestination(owner: Logger.log, writeToFile: Logger.defaultLogFile(), identifier: "CoreTracker.logFile")
        
        fileLogDestination.outputLevel = .verbose
        fileLogDestination.showLogIdentifier = false
        fileLogDestination.showFunctionName = false
        fileLogDestination.showThreadName = false
        fileLogDestination.showLevel = true
        fileLogDestination.showFileName = false
        fileLogDestination.showLineNumber = false
        fileLogDestination.showDate = true
        fileLogDestination.targetMaxLogFiles = 1;
        fileLogDestination.autoRotationCompletion = { (success:Bool, archivedFile:String?) in
            if success, let path = archivedFile {
                Logger.log.info("\(UIDevice().type) UDID: \(UIDevice.current.identifierForVendor!.uuidString)")
                uploadFirebaseLog(path: path)
            }
        }
        
        // Process this destination in the background
        fileLogDestination.logQueue = XCGLogger.logQueue
        
        Logger.log.add(destination: fileLogDestination)
        
        // Add basic app info, version info etc, to the start of the logs
        Logger.log.info("\(UIDevice().type) UDID: \(UIDevice.current.identifierForVendor!.uuidString)")
        Logger.log.logAppDetails()


    }
    
    static let logBaseFileName = "/tracker.log"
    
    static var logDirectory: String {
        let url = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/logs")
        createDirectory(url)
        return url.path
    }
    
    static var archiveDirectory: String {
        let url = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/archive")
        createDirectory(url)
        return url.path
    }

    class fileprivate func createDirectory(_ url:URL) {
        if FileManager.default.fileExists(atPath: url.path) == false {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                Logger.log.error(error)
            }
        }
    }
    
    class func defaultLogFile() -> String {
        return logDirectory + logBaseFileName
    }
    
    class func zippedLogFileName(directory:String = archiveDirectory) -> String? {
        let logZipPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/log.zip"
        
        do {
            try FileManager.default.removeItem(atPath: logZipPath)
        }
        catch {
            DispatchQueue.main.async {
                Logger.log.error(error)
            }
        }
        
        if SSZipArchive.createZipFile(atPath: logZipPath, withContentsOfDirectory: directory) == false {
            DispatchQueue.main.async {
                Logger.log.error("Failed zipping the log file!")
            }
        }
        
        return logZipPath
    }
    
    
    class func zippedLogArchive() -> NSData? {
        
        if let zipFile = Logger.zippedLogFileName() {
            return NSData(contentsOfFile: zipFile)
        }
        return nil
    }
    
}

// MARKER: - Firebase

extension Logger {
    
    class func uploadFirebaseLog(path: String) {
        
        // Data in memory
        guard let data = NSData(contentsOfFile: path) as Data? else { return }

        let storageRef = Storage.storage().reference().child("iOS/\(UIDevice.current.identifierForVendor!.uuidString)/\(URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent).zip")

        storageRef.putData(data, metadata: nil) { (metaData, error) in
            if error != nil {
                Logger.log.error("ERROR uploading to FirebaseStorage: \(storageRef.fullPath) \(String(describing: error!.localizedDescription))")
            }
            else if let url = metaData?.downloadURL() {
                Logger.log.info("Successfully uploaded logs to FirebaseStorage: \(url)")
            }
        }
    }
}
