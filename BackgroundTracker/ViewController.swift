//
//  ViewController.swift
//  BackgroundTracker
//
//  Created by Rotem Rubnov on 03/05/2017.
//  Copyright © 2017 100grams. All rights reserved.
//

import UIKit
import MessageUI

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = ""
        
        // start tracking location
        // TODO: move this to a dedicated VC that explains to the user why location tracking is required
        LocationTracker.sharedInstance.trackingEnabled = true

        let textViewDestination = TextViewDestination(owner: Logger.log, identifier: "TrackerLogger.textViewDestination", textView: textView)
        
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
                if let zipFile = Logger.zip(directory: Logger.logDirectory),
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

