//
//  NotificationsUtility.swift
//  BackgroundTracker
//
//  Created by Rajeev Bhatia on 10/17/17.
//  Copyright © 2017 100grams. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationsUtility {
    
    static func requestForPermissions() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
        }
        
    }
    
    static func showLocalNotification(title: String, message: String) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default()
        
        let request = UNNotificationRequest.init(identifier: title + message, content: content, trigger: nil)
        
        // Schedule the notification.
        let center = UNUserNotificationCenter.current()
        center.add(request)
        
    }
    
}
