import Foundation
import UserNotifications

enum Notifs {
    static let waterHours = [10, 12, 14, 16, 18, 20]

    static var managedIds: [String] {
        var ids: [String] = (1...7).map { "train_\($0)" }
        ids += waterHours.map { "water_\($0)" }
        ids.append("evening")
        return ids
    }

    static func reschedule(profile p: Profile) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.removePendingNotificationRequests(withIdentifiers: managedIds)

            if p.remindersOn {
                for wd in 1...7 {
                    let content = UNMutableNotificationContent()
                    let isTraining = p.trainingWeekdays.contains(wd)
                    content.title = isTraining ? "C'est l'heure. 🔥" : "Jour de repos actif"
                    content.body = isTraining
                        ? Quotes.random
                        : "Pas de salle aujourd'hui ? Ton défi du jour t'attend. Aucune excuse."
                    content.sound = .default
                    var dc = DateComponents()
                    dc.weekday = wd
                    dc.hour = p.reminderHour
                    dc.minute = p.reminderMinute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                    center.add(UNNotificationRequest(identifier: "train_\(wd)", content: content, trigger: trigger))
                }

                let evening = UNMutableNotificationContent()
                evening.title = "Bilan du jour"
                evening.body = "Eau, protéines, sommeil, défi : as-tu validé tes missions ? Un guerrier ne laisse rien au hasard."
                evening.sound = .default
                var edc = DateComponents()
                edc.hour = 21
                edc.minute = 30
                center.add(UNNotificationRequest(identifier: "evening", content: evening,
                                                 trigger: UNCalendarNotificationTrigger(dateMatching: edc, repeats: true)))
            }

            if p.waterRemindersOn {
                for h in waterHours {
                    let c = UNMutableNotificationContent()
                    c.title = "Hydrate-toi 💧"
                    c.body = "Un verre d'eau maintenant. Les muscles sont faits à 75 % d'eau."
                    c.sound = .default
                    var dc = DateComponents()
                    dc.hour = h
                    dc.minute = 0
                    center.add(UNNotificationRequest(identifier: "water_\(h)", content: c,
                                                     trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)))
                }
            }
        }
    }

    static func scheduleRest(seconds: Int) {
        guard seconds > 0 else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["rest"])
        let c = UNMutableNotificationContent()
        c.title = "Repos terminé"
        c.body = "Série suivante. Maintenant."
        c.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        center.add(UNNotificationRequest(identifier: "rest", content: c, trigger: trigger))
    }

    static func cancelRest() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest"])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
