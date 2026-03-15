//
//  NotificationManager.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 11/30/25.
//
import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            #if DEBUG
            if let error = error {
                print("Notification auth error: \(error)")
            } else {
                print("Notifications granted: \(granted)")
            }
            #endif
        }
    }

    func scheduleDailyTipNotification(at time: DateComponents) {
        let center = UNUserNotificationCenter.current()

        // Only schedule if the user has granted permission — silently skip if they revoked it.
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                #if DEBUG
                print("⚠️ Notification permission not granted — skipping schedule")
                #endif
                return
            }

            center.removePendingNotificationRequests(withIdentifiers: ["dailyCJISTip"])

            let content = UNMutableNotificationContent()
            content.title = "CJIS Tip of the Day"
            content.body = "Open CJIS Daily for today's tip."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)

            let request = UNNotificationRequest(identifier: "dailyCJISTip",
                                                content: content,
                                                trigger: trigger)
            center.add(request) { error in
                #if DEBUG
                if let error = error {
                    print("⚠️ Error scheduling notification: \(error)")
                }
                #endif
            }
        }
    }
}
