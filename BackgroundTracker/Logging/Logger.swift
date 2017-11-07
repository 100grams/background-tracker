//
//  Logger.swift
//  Capture
//
//  Created by Rotem Rubnov on 06/09/16.
//  Copyright © 2016 100grams BV. All rights reserved.
//

import Trckr
import FirebaseStorage

class Logger: NSObject {

    // Create a logger object with no destinations
    static let log = TrckrLog.log
    
    class func start() {
        TrckrLog.start()
        TrckrLog.didRotateLogFile = { path in
            let url = URL(fileURLWithPath: path)
            guard let zipFile = TrckrLog.zip(contentsOf: url) else { return }
            guard let data = NSData(contentsOf: zipFile) as Data? else { return }
            
            let storageRef = Storage.storage().reference().child("iOS/\(UIDevice.current.identifierForVendor!.uuidString)/\(zipFile.lastPathComponent)")
            
            storageRef.putData(data, metadata: nil) { (metaData, error) in
                if error != nil {
                    TrckrLog.log.error("ERROR uploading to FirebaseStorage: \(storageRef.fullPath) \(String(describing: error!.localizedDescription))")
                }
                else if let url = metaData?.downloadURL() {
                    TrckrLog.log.info("Successfully uploaded logs to FirebaseStorage: \(url)")
                }
            }
        }
    }
    
}
