//
//  Logger.swift
//  Capture
//
//  Created by Rotem Rubnov on 06/09/16.
//  Copyright © 2016 100grams BV. All rights reserved.
//

import Trckr
import XCGLogger
import SSZipArchive
import FirebaseStorage

class Logger: NSObject {

    // Create a logger object with no destinations
    static let log = XCGLogger(identifier: "MainLog", includeDefaultDestinations: true)

    class func start() {
        TrckrLog.start()
        TrckrLog.didRotateLogFile = { path in
            let url = URL(fileURLWithPath: path)
            guard let zipFile = zip(contentsOf: url) else { return }
            guard let data = NSData(contentsOf: zipFile) as Data? else { return }
            
            let storageRef = Storage.storage().reference().child("iOS/\(UIDevice.current.identifierForVendor!.uuidString)/\(zipFile.lastPathComponent)")
            
            storageRef.putData(data, metadata: nil) { (metaData, error) in
                if error != nil {
                    log.error("ERROR uploading to FirebaseStorage: \(storageRef.fullPath) \(String(describing: error!.localizedDescription))")
                }
                else if let url = metaData?.downloadURL() {
                    log.info("Successfully uploaded logs to FirebaseStorage: \(url)")
                }
            }
        }
    }
    
    
    /**
     zip `directory` and return the file URL of the zip
     */
    class func zip(directory:String) -> URL? {
        let logZipPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/log.zip"
        cleanZip(path:logZipPath)
        
        if SSZipArchive.createZipFile(atPath: logZipPath, withContentsOfDirectory: directory) == false {
            DispatchQueue.main.async {
                log.error("Failed zipping the log file!")
            }
            return nil
        }
        
        return URL(fileURLWithPath: logZipPath)
    }
    
    /**
     zip `url` and return the file URL of the zip
     */
    class func zip(contentsOf url:URL) -> URL? {
        let logZipPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/\(url.deletingPathExtension().lastPathComponent).zip"
        cleanZip(path:logZipPath)
        
        if SSZipArchive.createZipFile(atPath: logZipPath, withFilesAtPaths: [url.path]) == false {
            DispatchQueue.main.async {
                log.error("Failed zipping the log file!")
            }
            return nil
        }
        
        return URL(fileURLWithPath: logZipPath)
    }
    
    class private func cleanZip(path:String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        }
        catch {
            DispatchQueue.main.async {
                log.error(error)
            }
        }
    }
    
    public class func zippedLogArchive() -> NSData? {
        
        if let zipFile = zip(directory:TrckrLog.archiveDirectory) {
            return NSData(contentsOf: zipFile)
        }
        return nil
    }

}
