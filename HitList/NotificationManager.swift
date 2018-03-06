//
//  NotificationManager.swift
//  HitList
//
//  Created by Mykhailo Tymchyshyn on 2/28/18.
//  Copyright © 2018 Mykhailo Tymchyshyn. All rights reserved.
//

import Foundation
import UserNotifications


class NotificationManager {
    let notificationTimeInterval = 3.0
    let uncenter = UNUserNotificationCenter.current()
    
    
    static let shared = NotificationManager()
    
    private var notificationObserver: NSObjectProtocol?
    func startListening() {
        notificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NewMessage , object: nil , queue: OperationQueue.main , using:
            { (notification)
                in
                let message = notification.userInfo?["message"] as! String
                let user = notification.userInfo?["sender"] as! String
//               let adresant = notification.userInfo?["to"] as! String
                let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey: user, arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: message, arguments: nil)
                content.sound = UNNotificationSound.default()
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: self.notificationTimeInterval, repeats: false)
                let request = UNNotificationRequest(identifier: "FiveSecond", content: content, trigger: trigger) // Schedule the notification.
                
                self.uncenter.add(request) { (error : Error?) in
                    if let theError = error {
                        // Handle any errors
                        print(theError)
                    }
                }
        }
        )
    }
    
    func stopListening() {
        NotificationCenter.default.removeObserver(notificationObserver as Any)
    }
}
