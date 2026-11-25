import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: Store
    @State private var showNoExcuse = false

    var body: some View {
        let unlocked = Achievements.all.filter { $0.check(store) }.count
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    RankCard()
                    SectionTitle("Progression").frame(maxWidth: .infinity, alignment: .leading)
                    NavRow("Succès", icon: "trophy.fill", subtitle: "\(unlocked)/\(Achievements.all.count) débloqués") {
                        AchievementsView()
                    }
                    NavRow("Rangs", icon: "crown.fill", subtitle: "De Grade 4 à Corps Céleste") {
                        RanksView()
                    }
                    SectionTitle("Outils").frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
                    Button { showNoExcuse = true } label: {
                        RowLabel(title: "Mode Sans Excuse", icon: "bolt.heart.fill", subtitle: "Citation + circuit 7 min")
                    }
                    .buttonStyle(.plain)
                    NavRow("Minuteur HIIT / circuits", icon: "timer", subtitle: "Tabata, brûle-graisse, finishers") {
                        HIITSetupView()
                    }
                    NavRow("Calculateur de 1RM", icon: "chart.bar.fill", subtitle: "Ta force maximale estimée") {
                        OneRMView()
                    }
                    NavRow("Calculateur de disques", icon: "circle.circle.fill", subtitle: "Quoi mettre sur la barre") {
                        PlateCalcView()
                    }
                    NavRow("Calories & macros", icon: "fork.knife", subtitle: "Combien manger pour ton objectif") {
                        NutritionView()
                    }
                    NavRow("Bibliothèque d'exercices", icon: "books.vertical.fill", subtitle: "\(Library.exercises.count) exercices expliqués") {
                        ExerciseLibraryView()
                    }
                    SectionTitle("App").frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
                    NavRow("Réglages", icon: "gearshape.fill", subtitle: "Profil, objectifs, rappels") {
                        SettingsView()
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Plus")
            .keyboardDoneButton()
            .sheet(isPresented: $showNoExcuse) {
                NoExcuseView().environmentObject(store)
            }
        }
    }
}

// MARK: - Succès & rangs

struct AchievementsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Achievements.all) { a in
                    let ok = a.check(store)
                    VStack(spacing: 8) {
                        Image(systemName: a.icon)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(ok ? Theme.gold : Theme.sub.opacity(0.5))
                            .frame(height: 40)
                        Text(a.title)
                            .font(.subheadline.weight(.heavy))
                            .foregroundColor(ok ? .white : Theme.sub)
                            .multilineTextAlignment(.center)
                        Text(a.desc)
                            .font(.caption2)
                            .foregroundColor(Theme.sub)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if !ok {
                            Image(systemName: "lock.fill").font(.caption2).foregroundColor(Theme.sub.opacity(0.6))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .background(ok ? Theme.gold.opacity(0.10) : Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(ok ? Theme.gold.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Succès")
    }
}

struct RanksView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let lvl = store.level
        ScrollView {
            VStack(spacing: 12) {
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle("Comment gagner de l'XP")
                        Text("• Séance terminée : 50 XP + 5 XP par série\n• Record battu : +25 XP\n• Défi du jour : +20 XP\n• Objectifs eau, protéines, sommeil, pas : +10 XP chacun\n• Zéro malbouffe : +10 XP · Étirements : +5 XP")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                ForEach(Ranks.all) { r in
                    let reached = lvl >= r.minLevel
                    let current = Ranks.forLevel(lvl).id == r.id
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(r.color.opacity(reached ? 0.2 : 0.05)).frame(width: 52, height: 52)
                            Image(systemName: r.icon)
                                .font(.title2.weight(.bold))
                                .foregroundColor(reached ? r.color : Theme.sub.opacity(0.4))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(r.name).font(.headline.weight(.black)).foregroundColor(reached ? .white : Theme.sub)
                                if current {
                                    Text("TOI").font(.caption2.weight(.black))
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Theme.accent).foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            Text("Niveau \(r.minLevel) · \(Levels.xpFor(level: r.minLevel)) XP")
                                .font(.caption.weight(.bold))
                                .foregroundColor(r.color.opacity(reached ? 1 : 0.5))
                            Text(r.lore)
                                .font(.caption)
                                .foregroundColor(Theme.sub)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(current ? r.color.opacity(0.08) : Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Rangs")
    }
}

// MARK: - HIIT

struct HIITSetupView: View {
    @State private var work = 40
    @State private var rest = 20
    @State private var rounds = 8
    @State private var phases: [HIITPhase] = []
    @State private var runTitle = ""
    @State private var run = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionTitle("Circuits prêts").frame(maxWidth: .infinity, alignment: .leading)
                ForEach(Circuits.presets) { c in
                    Button {
                        runTitle = c.name
                        phases = c.phases
                        run = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(c.name).font(.headline).foregroundColor(.white)
                                Text("\(c.description) · ~\(c.totalMinutes) min")
                                    .font(.caption).foregroundColor(Theme.sub)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill").font(.title).foregroundColor(Theme.accent)
                        }
                        .padding()
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                SectionTitle("Intervalles personnalisés").frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
                Card {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            preset("Tabata", 20, 10, 8)
                            preset("40/20", 40, 20, 10)
                            preset("30/30", 30, 30, 12)
                        }
                        Stepper("Effort : \(work) s", value: $work, in: 5...300, step: 5)
                        Stepper("Repos : \(rest) s", value: $rest, in: 0...300, step: 5)
                        Stepper("Rounds : \(rounds)", value: $rounds, in: 1...50)
                        Text("Durée totale : \(Fmt.clock(rounds * work + max(0, rounds - 1) * rest + 10))")
                            .font(.caption)
                            .foregroundColor(Theme.sub)
                        Button {
                            runTitle = "Intervalles \(work)/\(rest)"
                            phases = Circuits.intervals(work: work, rest: rest, rounds: rounds)
                            run = true
                        } label: {
                            Label("Lancer", systemImage: "play.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .foregroundColor(.white)
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Minuteur HIIT")
        .fullScreenCover(isPresented: $run) {
            HIITRunnerView(title: runTitle, phases: phases)
        }
    }

    private func preset(_ name: String, _ w: Int, _ r: Int, _ n: Int) -> some View {
        Button {
            work = w
            rest = r
            rounds = n
            Haptics.tap()
        } label: {
            Text(name)
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Theme.card2)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 1RM

struct OneRMView: View {
    @State private var weight: Double? = nil
    @State private var reps: Double? = nil

    private var oneRM: Double? {
        guard let w = weight, let r = reps, w > 0, r >= 1, r <= 30 else { return nil }
        let n = Int(r)
        if n == 1 { return w }
        let epley = w * (1 + Double(n) / 30)
        let brzycki = w * 36 / (37 - Double(n))
        return (epley + brzycki) / 2
    }

    private let table: [(Int, Int)] = [(100, 1), (95, 2), (90, 4), (85, 6), (80, 8), (75, 10), (70, 12), (65, 15), (60, 18)]

    private func loadFor(_ max: Double, _ pct: Int) -> Double {
        let raw = max * Double(pct) / 100.0
        return (raw / 2.5).rounded() * 2.5
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Ta série")
                        HStack {
                            DecimalInput(placeholder: "Charge (kg)", value: $weight).inputStyle()
                            DecimalInput(placeholder: "Répétitions", value: $reps, integer: true).inputStyle()
                        }
                    }
                }
                if let m = oneRM {
                    Card {
                        VStack(spacing: 6) {
                            SectionTitle("1RM estimé")
                            Text("\(m.rounded().clean) kg")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundColor(Theme.gold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle("Charges de travail")
                            ForEach(table.indices, id: \.self) { i in
                                let pct = table[i].0
                                let r = table[i].1
                                HStack {
                                    Text("\(pct) %").foregroundColor(Theme.sub).frame(width: 60, alignment: .leading)
                                    Text("≈ \(r) reps").foregroundColor(Theme.sub)
                                    Spacer()
                                    Text("\(loadFor(m, pct).clean) kg")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                } else {
                    Text("Entre une charge et un nombre de répétitions (1 à 30) pour estimer ton maximum sur une répétition, sans risque.")
                        .font(.subheadline)
                        .foregroundColor(Theme.sub)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Calculateur 1RM")
    }
}

// MARK: - Disques

struct PlateCalcView: View {
    @State private var target: Double? = nil
    @State private var bar: Double = 20

    private let plates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    private var perSide: [Double] {
        guard let t = target, t > bar else { return [] }
        var rem = (t - bar) / 2
        var res: [Double] = []
        for p in plates {
            while rem >= p - 0.001 {
                res.append(p)
                rem -= p
            }
        }
        return res
    }

    private var leftover: Double {
        guard let t = target, t > bar else { return 0 }
        return (t - bar) - perSide.reduce(0, +) * 2
    }

    private func color(_ p: Double) -> Color {
        switch p {
        case 25: return .red
        case 20: return .blue
        case 15: return .yellow
        case 10: return .green
        case 5: return .white
        case 2.5: return Color(red: 0.8, green: 0.2, blue: 0.2)
        default: return .gray
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Charge totale voulue")
                        DecimalInput(placeholder: "ex : 80 kg", value: $target).inputStyle()
                        Picker("Barre", selection: $bar) {
                            Text("Barre 20 kg").tag(20.0)
                            Text("Barre 15 kg").tag(15.0)
                            Text("Barre 10 kg").tag(10.0)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                if !perSide.isEmpty {
                    Card {
                        VStack(spacing: 14) {
                            SectionTitle("Par côté")
                            HStack(alignment: .center, spacing: 3) {
                                Rectangle().fill(Color.gray).frame(width: 40, height: 10)
                                ForEach(Array(perSide.enumerated()), id: \.offset) { _, p in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(color(p))
                                        .frame(width: p >= 10 ? 16 : 11, height: CGFloat(50 + p * 4))
                                }
                                Rectangle().fill(Color.gray).frame(width: 14, height: 10)
                            }
                            Text(perSide.map { "\($0.clean)" }.joined(separator: " + ") + " kg")
                                .font(.headline)
                                .foregroundColor(.white)
                            if leftover > 0.01 {
                                Text("Impossible pile avec ces disques : il manque \(leftover.clean) kg.")
                                    .font(.caption).foregroundColor(Theme.gold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else if let t = target, t <= bar {
                    Text("La barre seule pèse déjà \(bar.clean) kg.").foregroundColor(Theme.sub)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Disques")
    }
}

// MARK: - Nutrition

enum Activity: String, CaseIterable, Identifiable {
    case sed = "Sédentaire"
    case light = "Léger (1-3 séances)"
    case moderate = "Modéré (3-5 séances)"
    case high = "Intense (6-7 séances)"
    var id: String { rawValue }
    var factor: Double {
        switch self {
        case .sed: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .high: return 1.725
        }
    }
}

struct NutritionView: View {
    @EnvironmentObject var store: Store
    @State private var activity: Activity = .moderate
    @State private var weight: Double? = nil
    @State private var loaded = false

    var body: some View {
        let p = store.data.profile
        let w = weight ?? store.currentWeight ?? 75
        let bmr = 10 * w + 6.25 * p.heightCm - 5 * Double(p.age) + (p.sex == .homme ? 5 : -161)
        let tdee = bmr * activity.factor
        let factor: Double = {
            switch p.goal {
            case .perte: return 0.80
            case .muscle: return 1.10
            case .recompo: return 0.92
            case .force: return 1.05
            }
        }()
        let target = tdee * factor
        let protein = (2.0 * w).rounded()
        let fat = (0.9 * w).rounded()
        let carbs = max(0, ((target - protein * 4 - fat * 9) / 4).rounded())
        let bmi = w / pow(p.heightCm / 100, 2)

        ScrollView {
            VStack(spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitle("Tes infos")
                        HStack {
                            Text("Poids (kg)").foregroundColor(.white)
                            Spacer()
                            DecimalInput(placeholder: "\(w.clean)", value: $weight)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                                .inputStyle()
                        }
                        Text("\(p.sex.rawValue) · \(p.age) ans · \(Int(p.heightCm)) cm · \(p.goal.rawValue)")
                            .font(.caption).foregroundColor(Theme.sub)
                        Picker("Activité", selection: $activity) {
                            ForEach(Activity.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.accent)
                    }
                }

                Card {
                    VStack(spacing: 6) {
                        SectionTitle("Ton objectif calorique")
                        Text("\(Int(target)) kcal")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundColor(Theme.gold)
                        Text("Maintien : \(Int(tdee)) kcal · Métabolisme de base : \(Int(bmr)) kcal")
                            .font(.caption).foregroundColor(Theme.sub)
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack(spacing: 10) {
                    StatTile(value: "\(Int(protein)) g", label: "protéines", icon: "fork.knife", color: Theme.accent)
                    StatTile(value: "\(Int(carbs)) g", label: "glucides", icon: "leaf.fill", color: Theme.green)
                    StatTile(value: "\(Int(fat)) g", label: "lipides", icon: "drop.fill", color: Theme.gold)
                }

                Button {
                    store.data.profile.proteinGoal = Int(protein)
                    Haptics.success()
                } label: {
                    Text("Utiliser \(Int(protein)) g comme objectif protéines")
                }
                .buttonStyle(PrimaryButtonStyle())

                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle("IMC")
                        Text(String(format: "%.1f", bmi)).font(.title2.weight(.black)).foregroundColor(.white)
                        Text("L'IMC ne fait pas la différence entre muscle et gras. Fie-toi surtout au miroir, au tour de taille et à tes performances.")
                            .font(.caption).foregroundColor(Theme.sub)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("Estimations (formule de Mifflin-St Jeor). Ajuste de ±150 kcal selon l'évolution de ton poids sur 2 semaines.")
                    .font(.caption2)
                    .foregroundColor(Theme.sub)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Calories & macros")
    }
}

// MARK: - Réglages

struct WeekdayPicker: View {
    @Binding var selection: [Int]
    private let days: [(Int, String)] = [(2, "L"), (3, "M"), (4, "M"), (5, "J"), (6, "V"), (7, "S"), (1, "D")]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days.indices, id: \.self) { i in
                let wd = days[i].0
                let on = selection.contains(wd)
                Button {
                    if on {
                        selection.removeAll { $0 == wd }
                    } else {
                        selection.append(wd)
                    }
                } label: {
                    Text(days[i].1)
                        .font(.subheadline.weight(.bold))
                        .frame(width: 36, height: 36)
                        .background(on ? Theme.accent : Theme.card2)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @State private var confirmReset = false

    private var timeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                Calendar.current.date(bySettingHour: store.data.profile.reminderHour,
                                      minute: store.data.profile.reminderMinute,
                                      second: 0, of: Date()) ?? Date()
            },
            set: { d in
                let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                var p = store.data.profile
                p.reminderHour = c.hour ?? 18
                p.reminderMinute = c.minute ?? 0
                store.data.profile = p
            }
        )
    }

    var body: some View {
        Form {
            Section("Profil") {
                TextField("Prénom / pseudo", text: $store.data.profile.name)
                Picker("Objectif", selection: $store.data.profile.goal) {
                    ForEach(Goal.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Sexe", selection: $store.data.profile.sex) {
                    ForEach(Sex.allCases) { Text($0.rawValue).tag($0) }
                }
                Stepper("Âge : \(store.data.profile.age) ans", value: $store.data.profile.age, in: 12...90)
                Stepper("Taille : \(Int(store.data.profile.heightCm)) cm", value: $store.data.profile.heightCm, in: 120...230, step: 1)
                HStack {
                    Text("Poids objectif (kg)")
                    Spacer()
                    DecimalInput(placeholder: "—", value: $store.data.profile.targetWeight)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }
            }
            .listRowBackground(Theme.card)

            Section("Entraînement") {
                Stepper("Séances / semaine : \(store.data.profile.daysPerWeek)", value: $store.data.profile.daysPerWeek, in: 1...7)
                Picker("Programme", selection: $store.data.profile.programId) {
                    ForEach(Library.programs) { Text($0.name).tag($0.id) }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Jours de salle")
                    WeekdayPicker(selection: $store.data.profile.trainingWeekdays)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Theme.card)

            Section {
                Toggle("Rappel quotidien", isOn: $store.data.profile.remindersOn)
                DatePicker("Heure du rappel", selection: timeBinding, displayedComponents: .hourAndMinute)
                Toggle("Rappels pour boire (toutes les 2 h)", isOn: $store.data.profile.waterRemindersOn)
            } header: {
                Text("Rappels")
            } footer: {
                Text("Les jours de salle : rappel motivant. Les autres jours : rappel du défi. Bilan du soir à 21h30.")
            }
            .listRowBackground(Theme.card)

            Section("Objectifs quotidiens") {
                Stepper("Eau : \(store.data.profile.waterGoal) verres (25 cl)", value: $store.data.profile.waterGoal, in: 4...20)
                Stepper("Protéines : \(store.data.profile.proteinGoal) g", value: $store.data.profile.proteinGoal, in: 40...300, step: 5)
                Stepper("Sommeil : \(store.data.profile.sleepGoal.clean) h", value: $store.data.profile.sleepGoal, in: 5...10, step: 0.5)
                Stepper("Pas : \(store.data.profile.stepsGoal)", value: $store.data.profile.stepsGoal, in: 2000...30000, step: 500)
            }
            .listRowBackground(Theme.card)

            Section {
                Button("Tout réinitialiser", role: .destructive) { confirmReset = true }
            } footer: {
                Text("Restriction v1.0 — toutes tes données restent sur ton téléphone.")
            }
            .listRowBackground(Theme.card)
        }
        .tint(Theme.accent)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Réglages")
        .onDisappear { Notifs.reschedule(profile: store.data.profile) }
        .alert("Tout effacer ?", isPresented: $confirmReset) {
            Button("Effacer", role: .destructive) { store.resetAll() }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Séances, poids, photos, XP… tout sera supprimé définitivement.")
        }
    }
}
