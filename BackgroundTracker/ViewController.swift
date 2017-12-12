//
//  ViewController.swift
//  BackgroundTracker
//
//  Created by Rotem Rubnov on 03/05/2017.
//  Copyright © 2017 100grams. All rights reserved.
//

import UIKit
import MessageUI
import Trckr
import CoreLocation

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    
        initScreenLogging()
        
        // start tracking location
        // TODO: move this to a dedicated VC that explains to the user why location tracking is required
        Trckr.shared.delegate = self
        Trckr.shared.trackingEnabled = true
        // minute hour day(month) month day(week)
//        Trckr.shared.trackingSchedule = "* 8-19 * * 1,2,3,4,5"
    }
    
    private func initScreenLogging() {
        textView.text = ""
        //init the textViewDestination. the identifier has a random string appended to it since the VC might be reused
        let textViewDestination = TextViewDestination(owner: Logger.log, identifier: "TrackerLogger.textViewDestination.\(randomString(length: 5))", textView: textView)
        
        textViewDestination.outputLevel = .debug
        textViewDestination.showLogIdentifier = false
        textViewDestination.showFunctionName = true
        textViewDestination.showThreadName = false
        textViewDestination.showLevel = true
        textViewDestination.showFileName = false
        textViewDestination.showLineNumber = false
        textViewDestination.showDate = true
        
        Logger.log.add(destination: textViewDestination)

    }
    // to generate the identifier for the textViewDestination
    private func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationsUtility.requestForPermissions()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sendLogs(_ sender: Any) {
        
        if MFMailComposeViewController.canSendMail() {
            
            DispatchQueue.global().async { [weak self] in
                if let zipFile = Logger.zip(directory:Log.archiveDirectory),
                    let data = NSData(contentsOf: zipFile) {
                    DispatchQueue.main.async {
                        let mailComposer = MFMailComposeViewController()
                        mailComposer.setSubject("CoreTracker Logs")
                        mailComposer.addAttachmentData(data as Data, mimeType: "application/zip", fileName: "logs.zip")
                        mailComposer.setToRecipients(["rotem@100grams.nl"])
                        mailComposer.mailComposeDelegate = self
                        
                        self?.present(mailComposer, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    // MARK - MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }


}

extension ViewController : TrckrDelegate {
    
    var trip : Bool? {
        get {
            return UserDefaults.standard.bool(forKey: "trip")
        }
        set(t) {
            UserDefaults.standard.set(t, forKey: "trip")
        }
    }

    func didStartTracking() {
        Logger.log.debug("Trckr started location tracking")
    }
    
    func didStopTracking() {
        Logger.log.debug("Trckr stopped location tracking")
        if trip == true {
            trip = false
            if let region = Geofence.shared.monitoredRegion() as? CLCircularRegion {
                NotificationsUtility.showLocalNotification(title: "Trip ended", message: "(\(region.center.latitude), \(region.center.longitude))")
                Logger.log.debug("Trip ended (\(region.center.latitude), \(region.center.longitude))")
            }
        }
    }
    
    
    func didCross(region: CLRegion, type: Geofence.RegionTriggerType, withinSchedule:Bool) {
        if region.identifier == Geofence.RegionId,
            let circle = region as? CLCircularRegion,
            trip != true {
            trip = true
            NotificationsUtility.showLocalNotification(title: "Trip started", message: "(\(circle.center.latitude), \(circle.center.longitude))")
            Logger.log.debug("Trip started (\(circle.center.latitude), \(circle.center.longitude))")
            if withinSchedule == false {
                // TODO: tag the trip as #personal immediately
            }
        }
        else if region.identifier == Beacon.RegionId,
            let beacon = region as? CLBeaconRegion {
            switch type {
            case .Exit:
                let message = "(\(String(describing: beacon.major))/\(String(describing: beacon.minor)))"
                NotificationsUtility.showLocalNotification(title: "Beacon EXIT", message: message)
                Logger.log.debug("Beacon EXIT (\(message))")
                break
            case .Entry:
                let message = "(\(String(describing: beacon.major))/\(String(describing: beacon.minor)))"
                NotificationsUtility.showLocalNotification(title: "Beacon ENTRY", message: message)
                Logger.log.debug("Beacon ENTRY (\(message))")
                break
            default:
                break
            }
        }
    }
    
    func shouldTrackOutsideSchedule() -> Bool {
        return true // test. In real life: depends on user's choice
    }
    
    func didChangeAuthorization(status: CLAuthorizationStatus) {
        switch status {
            // we'd like to get "always" access in order to track locations in the background
        case .authorizedWhenInUse, .restricted, .denied:
            showAlertLocationSettings()
            break
        default:
            break
        }
    }
    
    func showAlertLocationSettings() {
        
        if let url = URL(string: UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(url) {
            
            let alert = UIAlertController(title: "Enable Location Access", message: "Enable Location Services for Passenger in iOS Settings > Privacy", preferredStyle: .alert)
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let ok = UIAlertAction(title: "Settings", style: .default, handler: { (action) in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            })
            
            alert.addAction(cancel)
            alert.addAction(ok)
            alert.preferredAction = ok
            present(alert, animated: true, completion: nil)
        }
    }
}
