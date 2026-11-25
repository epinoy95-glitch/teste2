import SwiftUI

// MARK: - Exercices

enum ExUnit: String {
    case reps, seconds, minutes
    var label: String {
        switch self {
        case .reps: return "reps"
        case .seconds: return "sec"
        case .minutes: return "min"
        }
    }
}

enum Muscle: String, CaseIterable, Identifiable {
    case pecs = "Pectoraux"
    case dos = "Dos"
    case jambes = "Jambes"
    case epaules = "Épaules"
    case bras = "Bras"
    case abdos = "Abdos"
    case cardio = "Cardio"
    var id: String { rawValue }
}

struct Exercise: Identifiable, Hashable {
    let id: String
    let name: String
    let muscle: Muscle
    let equipment: String
    let tips: String
    let bodyweight: Bool
    let unit: ExUnit
}

fileprivate func E(_ id: String, _ name: String, _ m: Muscle, _ eq: String, _ tips: String,
                   bw: Bool = false, unit: ExUnit = .reps) -> Exercise {
    Exercise(id: id, name: name, muscle: m, equipment: eq, tips: tips, bodyweight: bw, unit: unit)
}

struct ProgramItem: Hashable {
    let ex: String
    let sets: Int
    let reps: String
    let rest: Int
}

struct ProgramDay: Identifiable, Hashable {
    let id: String
    let name: String
    let items: [ProgramItem]
}

struct Program: Identifiable, Hashable {
    let id: String
    let name: String
    let level: String
    let days: String
    let description: String
    let workouts: [ProgramDay]
}

fileprivate func I(_ ex: String, _ sets: Int, _ reps: String, _ rest: Int = 90) -> ProgramItem {
    ProgramItem(ex: ex, sets: sets, reps: reps, rest: rest)
}

enum Library {
    static let exercises: [Exercise] = [
        // Pectoraux
        E("bench", "Développé couché (barre)", .pecs, "Barre + banc", "Omoplates serrées et basses, pieds ancrés au sol. Descends la barre au milieu des pecs, coudes à ~45°, puis pousse fort."),
        E("incline_db", "Développé incliné haltères", .pecs, "Haltères + banc incliné", "Banc à 30°. Descends les haltères sur les côtés du haut des pecs, contrôle la descente, pousse en rapprochant légèrement."),
        E("chest_press", "Chest press (machine)", .pecs, "Machine", "Règle le siège pour que les poignées soient à hauteur du milieu des pecs. Pousse sans verrouiller les coudes."),
        E("cable_fly", "Écarté poulie vis-à-vis", .pecs, "Poulies", "Bras légèrement fléchis, ramène les mains devant toi comme pour faire un câlin. Serre les pecs 1 seconde."),
        E("pushup", "Pompes", .pecs, "Poids du corps", "Corps gainé en planche, mains un peu plus larges que les épaules. Poitrine jusqu'au sol, pousse en expirant.", bw: true),
        E("dips", "Dips", .pecs, "Barres parallèles", "Penche le buste en avant pour cibler les pecs. Descends jusqu'à ce que les épaules soient au niveau des coudes.", bw: true),
        // Dos
        E("pullup", "Tractions", .dos, "Barre fixe", "Prise un peu plus large que les épaules. Tire les coudes vers les hanches, menton au-dessus de la barre. Descente contrôlée.", bw: true),
        E("lat_pulldown", "Tirage vertical", .dos, "Poulie haute", "Buste légèrement incliné, tire la barre vers le haut de la poitrine en sortant la cage thoracique."),
        E("barbell_row", "Rowing barre", .dos, "Barre", "Buste penché à ~45°, dos plat. Tire la barre vers le nombril en serrant les omoplates."),
        E("db_row", "Rowing haltère un bras", .dos, "Haltère + banc", "Un genou et une main sur le banc. Tire l'haltère vers la hanche, pas vers l'épaule."),
        E("seated_row", "Tirage horizontal (poulie)", .dos, "Poulie basse", "Dos droit, tire la poignée vers le ventre et serre les omoplates. Ne balance pas le buste."),
        E("deadlift", "Soulevé de terre", .dos, "Barre", "Barre collée aux tibias, dos neutre, gaine fort. Pousse le sol avec les jambes puis verrouille les hanches. Jamais le dos rond."),
        E("face_pull", "Face pull", .dos, "Poulie + corde", "Corde à hauteur du visage, tire vers le front en écartant les mains. Excellent pour la santé des épaules."),
        // Jambes
        E("squat", "Squat (barre)", .jambes, "Barre + rack", "Pieds largeur d'épaules, genoux dans l'axe des pieds. Descends au moins à la parallèle, poitrine haute, remonte en poussant le sol."),
        E("goblet_squat", "Goblet squat", .jambes, "Haltère / kettlebell", "Haltère contre la poitrine, descends entre tes genoux en gardant le buste droit. Parfait pour apprendre le squat."),
        E("leg_press", "Presse à cuisses", .jambes, "Machine", "Pieds largeur d'épaules au milieu du plateau. Descends jusqu'à 90° sans décoller le bas du dos."),
        E("rdl", "Soulevé de terre roumain", .jambes, "Barre / haltères", "Jambes presque tendues, recule les fesses en gardant le dos plat. Descends jusqu'à sentir l'étirement des ischios."),
        E("lunges", "Fentes marchées", .jambes, "Haltères ou poids du corps", "Grand pas en avant, genou arrière proche du sol, buste droit. Alterne les jambes."),
        E("leg_curl", "Leg curl", .jambes, "Machine", "Ramène les talons vers les fesses en contrôlant. Ne décolle pas les hanches."),
        E("leg_ext", "Leg extension", .jambes, "Machine", "Tends les jambes et serre les quadriceps 1 seconde en haut. Descente lente."),
        E("hip_thrust", "Hip thrust", .jambes, "Barre + banc", "Haut du dos sur le banc, barre sur les hanches. Pousse les hanches vers le haut et serre les fessiers."),
        E("calf_raise", "Mollets debout", .jambes, "Machine / marche", "Monte le plus haut possible sur la pointe des pieds, pause, puis descends bien bas."),
        E("jump_squat", "Squats sautés", .jambes, "Poids du corps", "Squat puis saut explosif. Réception souple, enchaîne directement.", bw: true),
        E("bw_squat", "Squats poids du corps", .jambes, "Poids du corps", "Bras devant, descends le plus bas possible en gardant les talons au sol.", bw: true),
        // Épaules
        E("ohp", "Développé militaire (barre)", .epaules, "Barre", "Debout, fessiers et abdos serrés. Pousse la barre au-dessus de la tête, la tête passe sous la barre."),
        E("db_press", "Développé haltères assis", .epaules, "Haltères + banc", "Dos contre le dossier, pousse les haltères au-dessus de la tête sans cambrer."),
        E("lateral_raise", "Élévations latérales", .epaules, "Haltères", "Monte les bras sur les côtés jusqu'à hauteur d'épaules, coudes légèrement fléchis. Léger et contrôlé."),
        E("rear_delt", "Oiseau (arrière d'épaule)", .epaules, "Haltères / machine", "Buste penché, écarte les bras vers l'extérieur en serrant l'arrière des épaules."),
        E("pike_pushup", "Pompes piquées", .epaules, "Poids du corps", "Fesses en l'air (V inversé), descends la tête vers le sol entre les mains.", bw: true),
        // Bras
        E("barbell_curl", "Curl barre", .bras, "Barre", "Coudes collés au corps, monte la barre sans balancer le buste. Descente lente."),
        E("hammer_curl", "Curl marteau", .bras, "Haltères", "Paumes face à face, monte les haltères. Travaille biceps et avant-bras."),
        E("incline_curl", "Curl incliné haltères", .bras, "Haltères + banc", "Allongé sur banc incliné, bras pendants. Gros étirement du biceps."),
        E("triceps_pushdown", "Extension triceps poulie", .bras, "Poulie haute", "Coudes fixes contre le corps, pousse vers le bas jusqu'à extension complète."),
        E("skullcrusher", "Barre au front", .bras, "Barre EZ + banc", "Allongé, descends la barre vers le front en gardant les coudes fixes, puis tends."),
        E("overhead_ext", "Extension triceps nuque", .bras, "Haltère / poulie", "Haltère derrière la tête, coudes vers le plafond, tends les bras."),
        E("bench_dips", "Dips entre deux bancs", .bras, "Banc / chaise", "Mains sur le banc derrière toi, descends en pliant les coudes à 90°.", bw: true),
        E("diamond_pushup", "Pompes diamant", .bras, "Poids du corps", "Mains collées en losange sous la poitrine. Cible les triceps.", bw: true),
        // Abdos
        E("plank", "Gainage planche", .abdos, "Poids du corps", "Sur les avant-bras, corps parfaitement droit. Serre fessiers et abdos, respire.", bw: true, unit: .seconds),
        E("hanging_leg_raise", "Relevés de jambes suspendu", .abdos, "Barre fixe", "Suspendu, monte les jambes en enroulant le bassin. Pas d'élan.", bw: true),
        E("cable_crunch", "Crunch à la poulie", .abdos, "Poulie + corde", "À genoux, enroule le buste vers le bas en contractant les abdos."),
        E("ab_wheel", "Roulette abdos", .abdos, "Roulette", "À genoux, roule vers l'avant en gardant le dos plat, reviens avec les abdos.", bw: true),
        E("mountain_climbers", "Mountain climbers", .abdos, "Poids du corps", "Position de pompe, ramène les genoux vers la poitrine en alternant vite.", bw: true, unit: .seconds),
        E("russian_twist", "Russian twist", .abdos, "Poids du corps / disque", "Assis, pieds décollés, tourne le buste de gauche à droite.", bw: true),
        // Cardio
        E("burpees", "Burpees", .cardio, "Poids du corps", "Accroupi, saute en planche, pompe, ramène les pieds, saut vertical. Le roi du cardio brutal.", bw: true),
        E("jumping_jacks", "Jumping jacks", .cardio, "Poids du corps", "Saute en écartant bras et jambes, reviens. Rythme soutenu.", bw: true, unit: .seconds),
        E("jump_rope", "Corde à sauter", .cardio, "Corde", "Petits sauts sur la pointe des pieds, poignets qui tournent, pas les bras.", bw: true, unit: .seconds),
        E("rower", "Rameur", .cardio, "Rameur", "Jambes, puis buste, puis bras. Retour dans l'ordre inverse.", bw: true, unit: .minutes),
        E("treadmill_incline", "Marche inclinée (tapis)", .cardio, "Tapis", "Pente 10-12 %, vitesse 5-6 km/h, sans te tenir. Brûle-graisse redoutable.", bw: true, unit: .minutes),
        E("bike", "Vélo", .cardio, "Vélo", "Résistance moyenne, cadence régulière. Parfait en fin de séance.", bw: true, unit: .minutes),
    ]

    static let byId: [String: Exercise] = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    static func exercise(_ id: String) -> Exercise {
        byId[id] ?? Exercise(id: id, name: id, muscle: .abdos, equipment: "—", tips: "", bodyweight: false, unit: .reps)
    }

    // MARK: Programmes

    static let programs: [Program] = [
        Program(
            id: "fullbody", name: "Full Body Débutant", level: "Débutant", days: "3 j / semaine",
            description: "Tout le corps à chaque séance. Le meilleur départ pour construire une base solide et apprendre les mouvements.",
            workouts: [
                ProgramDay(id: "fb_a", name: "Full Body A", items: [
                    I("goblet_squat", 3, "10-12", 90), I("bench", 3, "8-10", 120), I("lat_pulldown", 3, "10-12", 90),
                    I("db_press", 3, "10-12", 90), I("hammer_curl", 2, "12", 60), I("plank", 3, "30-45", 60)
                ]),
                ProgramDay(id: "fb_b", name: "Full Body B", items: [
                    I("rdl", 3, "10", 120), I("incline_db", 3, "10-12", 90), I("seated_row", 3, "10-12", 90),
                    I("lunges", 3, "10", 90), I("triceps_pushdown", 2, "12-15", 60), I("hanging_leg_raise", 3, "10", 60)
                ]),
                ProgramDay(id: "fb_c", name: "Full Body C", items: [
                    I("leg_press", 3, "12", 120), I("pushup", 3, "max", 90), I("db_row", 3, "10", 90),
                    I("lateral_raise", 3, "15", 60), I("barbell_curl", 2, "10-12", 60), I("treadmill_incline", 1, "15", 0)
                ]),
            ]),
        Program(
            id: "upperlower", name: "Haut / Bas", level: "Intermédiaire", days: "4 j / semaine",
            description: "Deux séances haut du corps, deux séances bas du corps. Plus de volume par muscle pour progresser vite.",
            workouts: [
                ProgramDay(id: "ul_ha", name: "Haut A", items: [
                    I("bench", 4, "6-8", 150), I("barbell_row", 4, "8", 120), I("ohp", 3, "8-10", 120),
                    I("lat_pulldown", 3, "10-12", 90), I("barbell_curl", 3, "10", 60), I("skullcrusher", 3, "10", 60)
                ]),
                ProgramDay(id: "ul_ba", name: "Bas A", items: [
                    I("squat", 4, "6-8", 180), I("rdl", 3, "8-10", 120), I("leg_press", 3, "12", 90),
                    I("leg_curl", 3, "12", 60), I("calf_raise", 4, "15", 60), I("plank", 3, "45", 60)
                ]),
                ProgramDay(id: "ul_hb", name: "Haut B", items: [
                    I("incline_db", 4, "8-10", 120), I("pullup", 4, "max", 120), I("db_press", 3, "10", 90),
                    I("seated_row", 3, "12", 90), I("lateral_raise", 3, "15", 60), I("hammer_curl", 3, "12", 60),
                    I("triceps_pushdown", 3, "12", 60)
                ]),
                ProgramDay(id: "ul_bb", name: "Bas B", items: [
                    I("deadlift", 3, "5", 180), I("hip_thrust", 3, "10", 90), I("lunges", 3, "12", 90),
                    I("leg_ext", 3, "15", 60), I("calf_raise", 4, "15", 60), I("hanging_leg_raise", 3, "12", 60)
                ]),
            ]),
        Program(
            id: "ppl", name: "Push / Pull / Legs", level: "Intermédiaire", days: "3 à 6 j / semaine",
            description: "Poussée, tirage, jambes. Fais le cycle une fois (3 j) ou deux fois (6 j) par semaine.",
            workouts: [
                ProgramDay(id: "ppl_push", name: "Push", items: [
                    I("bench", 4, "6-8", 150), I("ohp", 3, "8-10", 120), I("incline_db", 3, "10", 90),
                    I("lateral_raise", 4, "15", 60), I("triceps_pushdown", 3, "12", 60), I("overhead_ext", 3, "12", 60)
                ]),
                ProgramDay(id: "ppl_pull", name: "Pull", items: [
                    I("deadlift", 3, "5", 180), I("pullup", 4, "max", 120), I("barbell_row", 3, "8-10", 120),
                    I("face_pull", 3, "15", 60), I("barbell_curl", 3, "10", 60), I("hammer_curl", 3, "12", 60)
                ]),
                ProgramDay(id: "ppl_legs", name: "Legs", items: [
                    I("squat", 4, "6-8", 180), I("rdl", 3, "10", 120), I("leg_press", 3, "12", 90),
                    I("leg_curl", 3, "12", 60), I("calf_raise", 4, "15", 60), I("ab_wheel", 3, "10", 60)
                ]),
            ]),
        Program(
            id: "force", name: "Force Brute 5×5", level: "Tous niveaux", days: "3 j / semaine",
            description: "Peu d'exercices, des charges lourdes. Ajoute 2,5 kg dès que tu valides tes 5×5. Simple. Brutal. Efficace.",
            workouts: [
                ProgramDay(id: "f_a", name: "Force A", items: [
                    I("squat", 5, "5", 180), I("bench", 5, "5", 180), I("barbell_row", 5, "5", 150)
                ]),
                ProgramDay(id: "f_b", name: "Force B", items: [
                    I("squat", 5, "5", 180), I("ohp", 5, "5", 180), I("deadlift", 1, "5", 180)
                ]),
            ]),
        Program(
            id: "bete", name: "Mode Bête (sans matériel)", level: "Tous niveaux", days: "3-4 j / semaine",
            description: "Aucune énergie, aucun matériel, aucune excuse. Juste ton corps. Faisable à la maison ou au parc.",
            workouts: [
                ProgramDay(id: "b_a", name: "Bête A", items: [
                    I("pushup", 4, "max", 90), I("bw_squat", 4, "25", 60), I("pike_pushup", 3, "10", 90),
                    I("jump_squat", 3, "15", 60), I("plank", 3, "60", 60), I("burpees", 3, "15", 90)
                ]),
                ProgramDay(id: "b_b", name: "Bête B", items: [
                    I("pullup", 4, "max", 120), I("bench_dips", 3, "15", 60), I("diamond_pushup", 3, "max", 90),
                    I("jump_squat", 4, "15", 60), I("mountain_climbers", 3, "40", 45), I("russian_twist", 3, "30", 45)
                ]),
            ]),
    ]

    static func program(_ id: String) -> Program {
        programs.first { $0.id == id } ?? programs[0]
    }
}

// MARK: - Niveaux & rangs

enum Levels {
    static func level(for xp: Int) -> Int {
        Int((Double(max(xp, 0)) / 40.0).squareRoot()) + 1
    }
    static func xpFor(level: Int) -> Int {
        40 * (level - 1) * (level - 1)
    }
}

struct Rank: Identifiable {
    let id: Int
    let name: String
    let minLevel: Int
    let icon: String
    let color: Color
    let lore: String
}

enum Ranks {
    static let all: [Rank] = [
        Rank(id: 0, name: "Grade 4", minLevel: 1, icon: "circle.fill", color: .gray,
             lore: "Tout commence ici. Le corps est faible, mais tu as décidé de te battre."),
        Rank(id: 1, name: "Grade 3", minLevel: 5, icon: "shield.fill", color: Color(red: 0.4, green: 0.85, blue: 0.5),
             lore: "Les premières habitudes sont là. Tu n'es plus celui d'avant."),
        Rank(id: 2, name: "Grade 2", minLevel: 10, icon: "bolt.fill", color: Color(red: 0.3, green: 0.75, blue: 1.0),
             lore: "La discipline remplace la motivation. Tu viens même quand tu n'as pas envie."),
        Rank(id: 3, name: "Grade 1", minLevel: 15, icon: "flame.fill", color: .orange,
             lore: "Ton corps change. Les autres commencent à le remarquer."),
        Rank(id: 4, name: "Semi-Grade Spécial", minLevel: 22, icon: "burst.fill", color: .purple,
             lore: "Tu soulèves ce qui t'écrasait avant. La salle est devenue ta maison."),
        Rank(id: 5, name: "Grade Spécial", minLevel: 30, icon: "crown.fill", color: Theme.gold,
             lore: "Peu arrivent jusqu'ici. Tu fais partie de l'élite."),
        Rank(id: 6, name: "Tueur de Sorciers", minLevel: 40, icon: "scope", color: Theme.accent,
             lore: "Pas de don, pas de raccourci. Seulement des années de travail. Et ça suffit."),
        Rank(id: 7, name: "Corps Céleste", minLevel: 50, icon: "sparkles", color: .white,
             lore: "Aucune énergie. Que de la chair, des os et de la volonté. Tu es devenu l'arme."),
    ]

    static func forLevel(_ l: Int) -> Rank { all.last { l >= $0.minLevel } ?? all[0] }
    static func next(after l: Int) -> Rank? { all.first { $0.minLevel > l } }
}

// MARK: - Citations & défis

enum Quotes {
    static let all: [String] = [
        "Personne ne viendra te sauver. Lève-toi et fais-le toi-même.",
        "Tu n'as pas besoin de motivation. Tu as besoin de discipline.",
        "Pas de talent ? Parfait. Le travail ne demande aucun talent.",
        "Le corps que tu veux est de l'autre côté de l'effort que tu évites.",
        "Chaque répétition est une promesse tenue envers toi-même.",
        "Tu ne perds jamais une séance. Tu la gagnes ou tu apprends.",
        "La douleur d'aujourd'hui, c'est la force de demain.",
        "Ceux qui se moquent aujourd'hui demanderont ton programme demain.",
        "Le canapé ne t'a jamais rendu plus fort.",
        "Tu es fatigué ? Bien. Maintenant fais quand même.",
        "Les excuses ne brûlent pas de calories.",
        "Un jour ou jour un. C'est toi qui choisis.",
        "Le miroir ne ment pas. Mais il change si tu travailles.",
        "Sois le plus discipliné de la salle, pas le plus fort. La force suivra.",
        "Tu n'as rien reçu à la naissance ? Alors prends tout par le travail.",
        "La régularité bat l'intensité. Viens. Encore. Et encore.",
        "Ton futur toi te regarde. Ne le déçois pas.",
        "Une mauvaise séance vaut mieux qu'une séance ratée.",
        "La faim de progresser doit être plus forte que l'envie d'abandonner.",
        "Ils dorment. Toi tu forges.",
        "Le confort est un poison lent.",
        "Arrête de compter les jours. Fais que chaque jour compte.",
        "Tu n'es pas en retard. Tu es exactement où tu commences.",
        "La salle ne juge pas. Elle récompense ceux qui reviennent.",
        "Aucune énergie spéciale. Que des muscles, des os et de la rage.",
        "Si c'était facile, tout le monde aurait ce corps.",
        "La motivation te fait commencer. L'habitude te fait continuer.",
        "Respecte ton corps : nourris-le, entraîne-le, repose-le.",
        "Ce n'est pas le poids qui est lourd. C'est l'envie d'abandonner.",
        "Tu veux des résultats de bête ? Entraîne-toi comme une bête.",
        "Sois patient avec les résultats, impitoyable avec l'effort.",
        "Le seul adversaire, c'est toi d'hier.",
        "Ton cerveau abandonnera 10 fois avant ton corps.",
        "Transpire maintenant, brille plus tard.",
        "Tu ne te ruines pas. Tu te reconstruis. Pierre par pierre.",
        "Tu n'as pas besoin d'être grand pour commencer. Tu dois commencer pour devenir grand.",
        "Une série de plus. Toujours une de plus.",
        "Ton corps peut tout supporter. C'est ton esprit qu'il faut convaincre.",
        "La différence entre qui tu es et qui tu veux être, c'est ce que tu fais.",
        "Les légendes ne naissent pas. Elles se construisent à la salle.",
        "Personne ne se souvient de ceux qui ont abandonné.",
        "Le plus dur, c'est de passer la porte de la salle. Le reste, c'est du bonus.",
        "Mange propre, dors bien, soulève lourd. Répète.",
        "Ils t'ont sous-estimé ? Laisse tes résultats répondre.",
        "Le prédateur ne demande pas la permission. Il chasse.",
        "Un corps se sculpte en mois. Un mental se forge en jours difficiles.",
        "La flemme est une ennemie. Traite-la comme telle.",
        "Ce soir, tu seras fier ou tu auras des regrets. Choisis.",
        "Ne compte pas sur la chance. Compte tes séries.",
        "Tu es plus fort que tu ne le crois. Prouve-le.",
    ]

    static var random: String { all.randomElement() ?? all[0] }
}

enum Challenges {
    static let all: [String] = [
        "100 pompes dans la journée (découpe comme tu veux)",
        "150 squats poids du corps dans la journée",
        "Gainage : 3 × 1 minute",
        "10 000 pas minimum",
        "30 burpees (en plusieurs fois si besoin)",
        "Zéro sucre ajouté aujourd'hui",
        "Douche froide de 1 minute",
        "60 fentes (30 par jambe)",
        "Bois 3 litres d'eau",
        "20 minutes de marche rapide",
        "Pas de réseaux sociaux avant midi",
        "10 minutes d'étirements / mobilité",
        "100 crunchs dans la journée",
        "5 × 10 dips sur une chaise",
        "Planche : 2 minutes cumulées",
        "Prends les escaliers partout aujourd'hui",
        "200 jumping jacks",
        "Chaise contre le mur : 3 × 45 secondes",
        "Au lit avant 23h",
        "Un légume à chaque repas",
        "50 pompes + 50 squats + 50 abdos",
        "5 minutes de corde à sauter (ou sautillements)",
        "Pompes diamant : 3 séries max",
        "Fentes sautées : 3 × 15",
        "Marche 30 minutes après le dîner",
        "Ni soda ni alcool aujourd'hui",
        "Superman (dos) : 3 × 20",
        "EMOM 10 min : 5 burpees au début de chaque minute",
        "Prépare tes repas de demain",
        "Écris 3 objectifs pour ta semaine",
    ]
}

enum Daily {
    static func index(_ date: Date, count: Int, salt: Int = 0) -> Int {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return abs(day + salt) % max(count, 1)
    }
    static func quote(_ d: Date = Date()) -> String { Quotes.all[index(d, count: Quotes.all.count)] }
    static func challenge(_ d: Date = Date()) -> String { Challenges.all[index(d, count: Challenges.all.count, salt: 7)] }
}

// MARK: - Circuits / HIIT

struct HIITPhase: Hashable {
    let name: String
    let seconds: Int
    let isWork: Bool
}

struct Circuit: Identifiable {
    let id: String
    let name: String
    let description: String
    let moves: [String]
    let work: Int
    let rest: Int
    var phases: [HIITPhase] { Circuits.build(moves: moves, work: work, rest: rest) }
    var totalMinutes: Int { max(1, (moves.count * (work + rest)) / 60) }
}

enum Circuits {
    static let noExcuse = Circuit(
        id: "noexcuse", name: "Circuit Sans Excuse",
        description: "7 minutes, zéro matériel. Valide ton défi du jour.",
        moves: ["Jumping jacks", "Pompes", "Squats", "Gainage", "Fentes alternées", "Burpees", "Mountain climbers"],
        work: 40, rest: 20)

    static let presets: [Circuit] = [
        noExcuse,
        Circuit(id: "abs", name: "Abdos d'acier",
                description: "Sangle abdominale en béton armé.",
                moves: ["Crunchs", "Gainage", "Relevés de jambes", "Russian twist", "Gainage latéral gauche", "Gainage latéral droit", "Mountain climbers", "Planche finale"],
                work: 40, rest: 15),
        Circuit(id: "burn", name: "Brûle-graisse",
                description: "Cardio explosif pour faire fondre le gras.",
                moves: ["Burpees", "Squats sautés", "Jumping jacks", "Mountain climbers", "Fentes sautées", "Sprint sur place", "Burpees", "Squats sautés", "Jumping jacks", "Sprint sur place"],
                work: 40, rest: 20),
        Circuit(id: "finisher", name: "Finisher Brutal",
                description: "À faire en fin de séance. Ne t'arrête pas.",
                moves: ["Pompes", "Squats", "Burpees", "Pompes", "Squats", "Burpees"],
                work: 45, rest: 15),
    ]

    static func build(moves: [String], work: Int, rest: Int) -> [HIITPhase] {
        var p: [HIITPhase] = [HIITPhase(name: "Prépare-toi", seconds: 10, isWork: false)]
        for (i, m) in moves.enumerated() {
            p.append(HIITPhase(name: m, seconds: work, isWork: true))
            if i < moves.count - 1 && rest > 0 {
                p.append(HIITPhase(name: "Repos", seconds: rest, isWork: false))
            }
        }
        return p
    }

    static func intervals(work: Int, rest: Int, rounds: Int) -> [HIITPhase] {
        let r = max(1, rounds)
        return build(moves: (1...r).map { "Round \($0)/\(r)" }, work: work, rest: rest)
    }
}
