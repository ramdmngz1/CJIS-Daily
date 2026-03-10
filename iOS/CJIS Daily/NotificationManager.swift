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
            if let error = error {
                print("Notification auth error: \(error)")
            } else {
                print("Notifications granted: \(granted)")
            }
        }
    }

    func scheduleDailyTipNotification(at time: DateComponents, tip: CJISTip?) {
        guard let tip = tip else {
            print("⚠️ No tip available — skipping notification reschedule, existing schedule preserved")
            return
        }

        let center = UNUserNotificationCenter.current()

        // Only schedule if the user has granted permission — silently skip if they revoked it.
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                print("⚠️ Notification permission not granted — skipping schedule")
                return
            }

            center.removeAllPendingNotificationRequests()

            let content = UNMutableNotificationContent()
            content.title = "CJIS Tip of the Day"
            content.body = tip.title
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)

            let request = UNNotificationRequest(identifier: "dailyCJISTip",
                                                content: content,
                                                trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("⚠️ Error scheduling notification: \(error)")
                }
            }
        }
    }
}
