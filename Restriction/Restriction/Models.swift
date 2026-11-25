import Foundation

enum Goal: String, Codable, CaseIterable, Identifiable {
    case perte = "Perdre du gras"
    case muscle = "Prendre du muscle"
    case recompo = "Les deux (recompo)"
    case force = "Devenir plus fort"
    var id: String { rawValue }
}

enum Sex: String, Codable, CaseIterable, Identifiable {
    case homme = "Homme"
    case femme = "Femme"
    var id: String { rawValue }
}

struct Profile: Codable {
    var name: String = ""
    var goal: Goal = .recompo
    var daysPerWeek: Int = 3
    var heightCm: Double = 175
    var age: Int = 20
    var sex: Sex = .homme
    var targetWeight: Double? = nil
    var onboarded: Bool = false
    var remindersOn: Bool = true
    var reminderHour: Int = 18
    var reminderMinute: Int = 0
    /// Jours (Calendar.weekday : 1 = dimanche, 2 = lundi ... 7 = samedi)
    var trainingWeekdays: [Int] = [2, 4, 6]
    var waterRemindersOn: Bool = false
    var waterGoal: Int = 8
    var proteinGoal: Int = 140
    var sleepGoal: Double = 8
    var stepsGoal: Int = 8000
    var programId: String = "fullbody"
}

struct SetEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var reps: Int
    var weight: Double
    var done: Bool = false
}

struct ExerciseLog: Codable, Identifiable, Hashable {
    var id = UUID()
    var exerciseId: String
    var sets: [SetEntry]
    var targetReps: String = ""
    var rest: Int = 90

    var doneSets: [SetEntry] { sets.filter { $0.done } }
    var volume: Double { doneSets.reduce(0) { $0 + Double($1.reps) * $1.weight } }
}

struct WorkoutSession: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var name: String
    var durationSec: Int
    var exercises: [ExerciseLog]
    var xp: Int
    var prs: [String] = []
    var feeling: Int = 3
    var note: String = ""
    var programDayId: String? = nil

    var volume: Double { exercises.reduce(0) { $0 + $1.volume } }
    var setsCount: Int { exercises.reduce(0) { $0 + $1.doneSets.count } }
}

struct WeightEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var kg: Double
}

struct MeasureEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var waist: Double?
    var chest: Double?
    var arm: Double?
    var thigh: Double?
    var hips: Double?
}

struct PhotoEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var fileName: String
}

struct DayHabits: Codable, Hashable {
    var water: Int = 0
    var sleep: Double = 0
    var protein: Int = 0
    var steps: Int = 0
    var challengeDone: Bool = false
    var noJunk: Bool = false
    var stretched: Bool = false
}

struct AppData: Codable {
    var profile = Profile()
    var sessions: [WorkoutSession] = []
    var weights: [WeightEntry] = []
    var measures: [MeasureEntry] = []
    var photos: [PhotoEntry] = []
    var habits: [String: DayHabits] = [:]
    var bonusXP: Int = 0
}

/// Estimation du 1RM (formule d'Epley)
func e1RM(weight: Double, reps: Int) -> Double {
    if reps <= 1 { return weight }
    return weight * (1 + Double(reps) / 30.0)
}

/// Score d'une série pour comparer les records.
/// Avec charge : 1RM estimé. Sans charge : nombre de reps (toujours inférieur à une série chargée).
func setScore(_ s: SetEntry) -> Double {
    if s.weight > 0 { return e1RM(weight: s.weight, reps: s.reps) }
    return Double(s.reps) * 0.001
}
