//
//  AppViewModel.swift
//  CJIS Daily
//
//  Created by Ramon Dominguez on 11/30/25.
//

import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var notificationTime: Date = Date()
    @Published var todayTips: [CJISTip] = []

    private let timeKey = "notificationTime"

    init() {
        loadNotificationTime()
        refreshTodayTips()
    }

    func refreshTodayTips(date: Date = Date()) {
        // Intentionally pick tips that have quiz questions so the 5-question Daily Check never breaks.
        todayTips = TipStore.shared.tipsForToday(count: 5, date: date, requireQuizQuestions: true)
    }

    func loadNotificationTime() {
        if let data = UserDefaults.standard.data(forKey: timeKey),
           let decoded = try? JSONDecoder().decode(Date.self, from: data) {
            notificationTime = decoded
        } else {
            // Default: 9:00 AM local time
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = 9
            comps.minute = 0
            notificationTime = Calendar.current.date(from: comps) ?? Date()
        }
    }

    func saveNotificationTime() {
        do {
            let data = try JSONEncoder().encode(notificationTime)
            UserDefaults.standard.set(data, forKey: timeKey)
        } catch {
            print("⚠️ Failed to encode notification time: \(error)")
        }

        // Use the first tip in today's pack for the notification body.
        let firstTip = todayTips.first
        let comps = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        NotificationManager.shared.scheduleDailyTipNotification(at: comps, tip: firstTip)
    }
}
