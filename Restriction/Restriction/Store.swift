import SwiftUI
import UIKit

struct WorkoutTemplate: Identifiable {
    let id = UUID()
    var name: String
    var programDayId: String?
    var logs: [ExerciseLog]
}

struct PersonalRecord: Identifiable {
    var id: String { exerciseId }
    let exerciseId: String
    let set: SetEntry
    let date: Date
}

struct WeekStat: Identifiable {
    let id: Date
    let sessions: Int
    let volume: Double
}

struct MuscleStat: Identifiable {
    let id: String
    let sets: Int
}

final class Store: ObservableObject {
    @Published var data: AppData {
        didSet { save() }
    }
    @Published var pendingWorkout: WorkoutTemplate? = nil

    private let fileURL: URL

    static var docs: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        c.timeZone = TimeZone.current
        return c
    }()

    init() {
        let url = Store.docs.appendingPathComponent("restriction_data.json")
        fileURL = url
        var loaded = AppData()
        if let raw = try? Data(contentsOf: url) {
            if let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
                loaded = decoded
            } else {
                // On garde une sauvegarde si le fichier est illisible
                let backup = Store.docs.appendingPathComponent("restriction_backup_\(Int(Date().timeIntervalSince1970)).json")
                try? raw.write(to: backup)
            }
        }
        _data = Published(initialValue: loaded)
    }

    private func save() {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            print("Erreur de sauvegarde : \(error)")
        }
    }

    // MARK: - XP & niveaux

    static func habitXP(_ h: DayHabits, profile p: Profile) -> Int {
        var xp = 0
        if h.water >= p.waterGoal { xp += 10 }
        if h.protein >= p.proteinGoal { xp += 10 }
        if h.sleep >= p.sleepGoal { xp += 10 }
        if h.steps >= p.stepsGoal { xp += 10 }
        if h.challengeDone { xp += 20 }
        if h.noJunk { xp += 10 }
        if h.stretched { xp += 5 }
        return xp
    }

    static let maxHabitXP = 75

    var totalXP: Int {
        let s = data.sessions.reduce(0) { $0 + $1.xp }
        let h = data.habits.values.reduce(0) { $0 + Store.habitXP($1, profile: data.profile) }
        return s + h + data.bonusXP
    }

    var level: Int { Levels.level(for: totalXP) }
    var rank: Rank { Ranks.forLevel(level) }

    // MARK: - Hygiène

    func habits(_ date: Date) -> DayHabits {
        data.habits[Fmt.dayKey(date)] ?? DayHabits()
    }

    func editHabits(_ date: Date, _ change: (inout DayHabits) -> Void) {
        var h = habits(date)
        change(&h)
        data.habits[Fmt.dayKey(date)] = h
    }

    // MARK: - Séances & séries

    var sessionsSorted: [WorkoutSession] {
        data.sessions.sorted { $0.date > $1.date }
    }

    var sessionDays: Set<String> {
        Set(data.sessions.map { Fmt.dayKey($0.date) })
    }

    private func isActive(_ date: Date, days: Set<String>) -> Bool {
        let k = Fmt.dayKey(date)
        return days.contains(k) || (data.habits[k]?.challengeDone ?? false)
    }

    var dayStreak: Int {
        let days = sessionDays
        let c = Store.cal
        var d = c.startOfDay(for: Date())
        if !isActive(d, days: days) {
            d = c.date(byAdding: .day, value: -1, to: d) ?? d
        }
        var n = 0
        while isActive(d, days: days) && n < 5000 {
            n += 1
            guard let prev = c.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return n
    }

    var bestDayStreak: Int {
        var keys = sessionDays
        for (k, h) in data.habits where h.challengeDone { keys.insert(k) }
        let dates = keys.compactMap { Fmt.dayKeyFormatter.date(from: $0) }.sorted()
        var best = 0, cur = 0
        var prev: Date? = nil
        for d in dates {
            if let p = prev, let diff = Store.cal.dateComponents([.day], from: p, to: d).day, diff == 1 {
                cur += 1
            } else {
                cur = 1
            }
            best = max(best, cur)
            prev = d
        }
        return max(best, dayStreak)
    }

    func sessions(inWeekOf date: Date) -> [WorkoutSession] {
        guard let iv = Store.cal.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return data.sessions.filter { iv.contains($0.date) }
    }

    var sessionsThisWeek: Int { sessions(inWeekOf: Date()).count }

    var weekStreak: Int {
        let goal = max(1, data.profile.daysPerWeek)
        var n = sessionsThisWeek >= goal ? 1 : 0
        guard var d = Store.cal.date(byAdding: .weekOfYear, value: -1, to: Date()) else { return n }
        var count = 0
        while sessions(inWeekOf: d).count >= goal && count < 520 {
            n += 1
            count += 1
            guard let prev = Store.cal.date(byAdding: .weekOfYear, value: -1, to: d) else { break }
            d = prev
        }
        return n
    }

    func lastLog(for exId: String) -> ExerciseLog? {
        for s in sessionsSorted {
            if let l = s.exercises.first(where: { $0.exerciseId == exId && !$0.doneSets.isEmpty }) {
                return l
            }
        }
        return nil
    }

    func bestScore(for exId: String) -> Double {
        var best = 0.0
        for s in data.sessions {
            for l in s.exercises where l.exerciseId == exId {
                for st in l.doneSets { best = max(best, setScore(st)) }
            }
        }
        return best
    }

    var records: [PersonalRecord] {
        var dict: [String: PersonalRecord] = [:]
        for s in data.sessions {
            for l in s.exercises {
                for st in l.doneSets {
                    if let cur = dict[l.exerciseId], setScore(cur.set) >= setScore(st) { continue }
                    dict[l.exerciseId] = PersonalRecord(exerciseId: l.exerciseId, set: st, date: s.date)
                }
            }
        }
        return dict.values.sorted { Library.exercise($0.exerciseId).name < Library.exercise($1.exerciseId).name }
    }

    var prCount: Int { data.sessions.reduce(0) { $0 + $1.prs.count } }
    var totalVolume: Double { data.sessions.reduce(0) { $0 + $1.volume } }
    var totalDuration: Int { data.sessions.reduce(0) { $0 + $1.durationSec } }
    var totalSets: Int { data.sessions.reduce(0) { $0 + $1.setsCount } }

    func weekStats(_ n: Int) -> [WeekStat] {
        let c = Store.cal
        guard let thisWeek = c.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        var res: [WeekStat] = []
        for i in stride(from: n - 1, through: 0, by: -1) {
            guard let start = c.date(byAdding: .weekOfYear, value: -i, to: thisWeek) else { continue }
            let ss = sessions(inWeekOf: start)
            res.append(WeekStat(id: start, sessions: ss.count, volume: ss.reduce(0) { $0 + $1.volume }))
        }
        return res
    }

    func muscleStats(days: Int) -> [MuscleStat] {
        let from = Date().addingTimeInterval(-Double(days) * 86400)
        var counts: [Muscle: Int] = [:]
        for s in data.sessions where s.date >= from {
            for l in s.exercises {
                counts[Library.exercise(l.exerciseId).muscle, default: 0] += l.doneSets.count
            }
        }
        return Muscle.allCases.map { MuscleStat(id: $0.rawValue, sets: counts[$0] ?? 0) }
    }

    // MARK: - Programme

    var currentProgram: Program { Library.program(data.profile.programId) }

    var nextProgramDay: ProgramDay {
        let p = currentProgram
        for s in sessionsSorted {
            if let dayId = s.programDayId, let idx = p.workouts.firstIndex(where: { $0.id == dayId }) {
                return p.workouts[(idx + 1) % p.workouts.count]
            }
        }
        return p.workouts[0]
    }

    static func defaultReps(_ s: String) -> Int {
        let parts = s.split(whereSeparator: { !$0.isNumber })
        if let f = parts.first, let n = Int(f) { return n }
        return 10
    }

    func template(for day: ProgramDay) -> WorkoutTemplate {
        let logs: [ExerciseLog] = day.items.map { item in
            let prevSets = lastLog(for: item.ex)?.doneSets ?? []
            let base = Store.defaultReps(item.reps)
            var sets: [SetEntry] = []
            for i in 0..<max(1, item.sets) {
                if !prevSets.isEmpty {
                    let ps = prevSets[min(i, prevSets.count - 1)]
                    sets.append(SetEntry(reps: ps.reps, weight: ps.weight))
                } else {
                    sets.append(SetEntry(reps: base, weight: 0))
                }
            }
            return ExerciseLog(exerciseId: item.ex, sets: sets, targetReps: item.reps, rest: item.rest)
        }
        return WorkoutTemplate(name: day.name, programDayId: day.id, logs: logs)
    }

    func newLog(for exId: String) -> ExerciseLog {
        let prevSets = lastLog(for: exId)?.doneSets ?? []
        var sets: [SetEntry] = []
        for i in 0..<3 {
            if !prevSets.isEmpty {
                let ps = prevSets[min(i, prevSets.count - 1)]
                sets.append(SetEntry(reps: ps.reps, weight: ps.weight))
            } else {
                sets.append(SetEntry(reps: 10, weight: 0))
            }
        }
        return ExerciseLog(exerciseId: exId, sets: sets, targetReps: "8-12", rest: 90)
    }

    func start(day: ProgramDay) {
        pendingWorkout = template(for: day)
    }

    func startEmpty() {
        pendingWorkout = WorkoutTemplate(name: "Séance libre", programDayId: nil, logs: [])
    }

    func finishWorkout(template: WorkoutTemplate, logs: [ExerciseLog], start: Date) -> WorkoutSession {
        let cleaned: [ExerciseLog] = logs.compactMap { l in
            var c = l
            c.sets = l.sets.filter { $0.done }
            return c.sets.isEmpty ? nil : c
        }
        var prs: [String] = []
        for l in cleaned {
            let prev = bestScore(for: l.exerciseId)
            let best = l.sets.map { setScore($0) }.max() ?? 0
            if prev > 0 && best > prev && !prs.contains(l.exerciseId) {
                prs.append(l.exerciseId)
            }
        }
        let setsDone = cleaned.reduce(0) { $0 + $1.sets.count }
        let xp = 50 + setsDone * 5 + prs.count * 25
        let duration = max(60, Int(Date().timeIntervalSince(start)))
        let session = WorkoutSession(date: start, name: template.name, durationSec: duration,
                                     exercises: cleaned, xp: xp, prs: prs,
                                     programDayId: template.programDayId)
        data.sessions.append(session)
        return session
    }

    func updateSession(_ id: UUID, _ change: (inout WorkoutSession) -> Void) {
        guard let i = data.sessions.firstIndex(where: { $0.id == id }) else { return }
        var s = data.sessions[i]
        change(&s)
        data.sessions[i] = s
    }

    func deleteSession(_ id: UUID) {
        data.sessions.removeAll { $0.id == id }
    }

    // MARK: - Poids & mesures

    var weightsSorted: [WeightEntry] { data.weights.sorted { $0.date < $1.date } }
    var currentWeight: Double? { weightsSorted.last?.kg }

    func addWeight(_ kg: Double, date: Date) {
        data.weights.append(WeightEntry(date: date, kg: kg))
    }

    func deleteWeight(_ id: UUID) {
        data.weights.removeAll { $0.id == id }
    }

    var measuresSorted: [MeasureEntry] { data.measures.sorted { $0.date < $1.date } }

    func deleteMeasure(_ id: UUID) {
        data.measures.removeAll { $0.id == id }
    }

    // MARK: - Photos

    func addPhoto(_ imageData: Data) {
        guard let img = UIImage(data: imageData) else { return }
        let resized = Store.resize(img, maxSide: 1600)
        guard let jpg = resized.jpegData(compressionQuality: 0.8) else { return }
        let name = "photo_\(UUID().uuidString).jpg"
        do {
            try jpg.write(to: Store.docs.appendingPathComponent(name), options: .atomic)
            data.photos.append(PhotoEntry(date: Date(), fileName: name))
        } catch {
            print("Erreur photo : \(error)")
        }
    }

    func image(for p: PhotoEntry) -> UIImage? {
        UIImage(contentsOfFile: Store.docs.appendingPathComponent(p.fileName).path)
    }

    func deletePhoto(_ p: PhotoEntry) {
        try? FileManager.default.removeItem(at: Store.docs.appendingPathComponent(p.fileName))
        data.photos.removeAll { $0.id == p.id }
    }

    static func resize(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return image }
        let scale = maxSide / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    // MARK: - Réinitialisation

    func resetAll() {
        for p in data.photos {
            try? FileManager.default.removeItem(at: Store.docs.appendingPathComponent(p.fileName))
        }
        Notifs.cancelAll()
        data = AppData()
    }
}

// MARK: - Succès

struct Achievement: Identifiable {
    let id: String
    let title: String
    let desc: String
    let icon: String
    let check: (Store) -> Bool
}

enum Achievements {
    static let all: [Achievement] = [
        Achievement(id: "first", title: "Premier sang", desc: "Termine ta première séance", icon: "drop.fill") { $0.data.sessions.count >= 1 },
        Achievement(id: "s10", title: "Habitué", desc: "10 séances terminées", icon: "10.circle.fill") { $0.data.sessions.count >= 10 },
        Achievement(id: "s50", title: "Pilier de la salle", desc: "50 séances terminées", icon: "building.columns.fill") { $0.data.sessions.count >= 50 },
        Achievement(id: "s100", title: "Centurion", desc: "100 séances terminées", icon: "shield.lefthalf.filled") { $0.data.sessions.count >= 100 },
        Achievement(id: "streak3", title: "Ça chauffe", desc: "3 jours actifs d'affilée", icon: "flame") { $0.bestDayStreak >= 3 },
        Achievement(id: "streak7", title: "Semaine de fer", desc: "7 jours actifs d'affilée", icon: "flame.fill") { $0.bestDayStreak >= 7 },
        Achievement(id: "streak30", title: "Inarrêtable", desc: "30 jours actifs d'affilée", icon: "bolt.heart.fill") { $0.bestDayStreak >= 30 },
        Achievement(id: "pr1", title: "Plus fort qu'hier", desc: "Bats ton premier record", icon: "trophy.fill") { $0.prCount >= 1 },
        Achievement(id: "pr10", title: "Briseur de limites", desc: "10 records battus", icon: "medal.fill") { $0.prCount >= 10 },
        Achievement(id: "vol10", title: "10 tonnes", desc: "10 000 kg soulevés au total", icon: "scalemass.fill") { $0.totalVolume >= 10_000 },
        Achievement(id: "vol100", title: "100 tonnes", desc: "100 000 kg soulevés au total", icon: "mountain.2.fill") { $0.totalVolume >= 100_000 },
        Achievement(id: "early", title: "Lève-tôt", desc: "Une séance avant 8 h", icon: "sunrise.fill") { s in
            s.data.sessions.contains { Calendar.current.component(.hour, from: $0.date) < 8 }
        },
        Achievement(id: "night", title: "Chasseur nocturne", desc: "Une séance après 21 h", icon: "moon.stars.fill") { s in
            s.data.sessions.contains { Calendar.current.component(.hour, from: $0.date) >= 21 }
        },
        Achievement(id: "water7", title: "Hydraté", desc: "Objectif d'eau atteint 7 jours", icon: "drop.circle.fill") { s in
            s.data.habits.values.filter { $0.water >= s.data.profile.waterGoal }.count >= 7
        },
        Achievement(id: "challenge10", title: "Relève les défis", desc: "10 défis du jour validés", icon: "checkmark.seal.fill") { s in
            s.data.habits.values.filter { $0.challengeDone }.count >= 10
        },
        Achievement(id: "weigh10", title: "Sous contrôle", desc: "10 pesées enregistrées", icon: "chart.xyaxis.line") { $0.data.weights.count >= 10 },
        Achievement(id: "photo", title: "Avant / Après", desc: "Ajoute ta première photo", icon: "camera.fill") { $0.data.photos.count >= 1 },
        Achievement(id: "week", title: "Contrat rempli", desc: "Atteins ton objectif de séances de la semaine", icon: "calendar.badge.checkmark") { $0.weekStreak >= 1 },
        Achievement(id: "lvl10", title: "Grade 2", desc: "Atteins le niveau 10", icon: "bolt.fill") { $0.level >= 10 },
        Achievement(id: "lvl30", title: "Grade Spécial", desc: "Atteins le niveau 30", icon: "crown.fill") { $0.level >= 30 },
    ]
}
