import SwiftUI

struct HabitsView: View {
    @EnvironmentObject var store: Store
    @State private var date = Date()

    private var isToday: Bool { Store.cal.isDateInToday(date) }

    private func bind<T>(_ kp: WritableKeyPath<DayHabits, T>) -> Binding<T> {
        Binding<T>(
            get: { store.habits(date)[keyPath: kp] },
            set: { v in store.editHabits(date) { $0[keyPath: kp] = v } }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    let h = store.habits(date)
                    let p = store.data.profile
                    dayNavigator
                    xpCard(h, p)
                    waterCard(h, p)
                    proteinCard(h, p)
                    sleepCard(h, p)
                    stepsCard(h, p)
                    checksCard
                    weekCard
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Hygiène de vie")
            .keyboardDoneButton()
        }
    }

    private var dayNavigator: some View {
        HStack {
            Button {
                date = Store.cal.date(byAdding: .day, value: -1, to: date) ?? date
            } label: {
                Image(systemName: "chevron.left.circle.fill").font(.title)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(isToday ? "Aujourd'hui" : Fmt.longDate.string(from: date).capitalized)
                    .font(.headline.weight(.heavy))
                    .foregroundColor(.white)
                if !isToday {
                    Button("Revenir à aujourd'hui") { date = Date() }
                        .font(.caption)
                }
            }
            Spacer()
            Button {
                let next = Store.cal.date(byAdding: .day, value: 1, to: date) ?? date
                if next <= Date() { date = next }
            } label: {
                Image(systemName: "chevron.right.circle.fill").font(.title)
            }
            .disabled(isToday)
            .opacity(isToday ? 0.3 : 1)
        }
        .foregroundColor(Theme.accent)
    }

    private func xpCard(_ h: DayHabits, _ p: Profile) -> some View {
        let xp = Store.habitXP(h, profile: p)
        return Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionTitle("XP hygiène du jour")
                    Spacer()
                    Text("\(xp)/\(Store.maxHabitXP) XP")
                        .font(.headline.weight(.black))
                        .foregroundColor(Theme.gold)
                }
                ProgressBar(value: Double(xp) / Double(Store.maxHabitXP), color: Theme.gold)
                Text("Les muscles se construisent à la salle, mais grandissent dans l'assiette et dans le lit.")
                    .font(.caption)
                    .foregroundColor(Theme.sub)
            }
        }
    }

    private func waterCard(_ h: DayHabits, _ p: Profile) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Eau", systemImage: "drop.fill").font(.headline).foregroundColor(Theme.water)
                    Spacer()
                    Text("\(h.water)/\(p.waterGoal) verres · \(String(format: "%.2f", Double(h.water) * 0.25)) L")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(0..<max(p.waterGoal, h.water + 1), id: \.self) { i in
                        Image(systemName: i < h.water ? "drop.fill" : "drop")
                            .font(.title2)
                            .foregroundColor(i < h.water ? Theme.water : Theme.sub)
                            .onTapGesture {
                                store.editHabits(date) { $0.water = (i + 1 == h.water) ? i : i + 1 }
                                Haptics.tap()
                            }
                    }
                }
                HStack {
                    Button { store.editHabits(date) { $0.water = max(0, $0.water - 1) } } label: {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    Button {
                        store.editHabits(date) { $0.water += 1 }
                        Haptics.tap()
                    } label: {
                        Label("1 verre", systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: Theme.water.opacity(0.8)))
                }
            }
        }
    }

    private func proteinCard(_ h: DayHabits, _ p: Profile) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Protéines", systemImage: "fork.knife").font(.headline).foregroundColor(Theme.accent)
                    Spacer()
                    Text("\(h.protein)/\(p.proteinGoal) g").font(.subheadline.weight(.bold)).foregroundColor(.white)
                }
                ProgressBar(value: Double(h.protein) / Double(max(1, p.proteinGoal)))
                HStack(spacing: 8) {
                    ForEach([-10, 10, 25, 40], id: \.self) { g in
                        Button {
                            store.editHabits(date) { $0.protein = max(0, $0.protein + g) }
                            Haptics.tap()
                        } label: {
                            Text(g > 0 ? "+\(g) g" : "\(g) g")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                Text("Repères : 100 g de poulet ≈ 25 g · 3 œufs ≈ 18 g · 1 shaker de whey ≈ 25 g · 200 g de skyr ≈ 20 g")
                    .font(.caption2)
                    .foregroundColor(Theme.sub)
            }
        }
    }

    private func sleepCard(_ h: DayHabits, _ p: Profile) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Sommeil", systemImage: "bed.double.fill").font(.headline).foregroundColor(.purple)
                    Spacer()
                    Text("objectif \(p.sleepGoal.clean) h").font(.caption).foregroundColor(Theme.sub)
                }
                Stepper(value: bind(\.sleep), in: 0...14, step: 0.5) {
                    Text("\(h.sleep.clean) h")
                        .font(.title2.weight(.black))
                        .foregroundColor(h.sleep >= p.sleepGoal ? Theme.green : .white)
                }
            }
        }
    }

    private func stepsCard(_ h: DayHabits, _ p: Profile) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Pas", systemImage: "figure.walk").font(.headline).foregroundColor(Theme.green)
                    Spacer()
                    Text("objectif \(p.stepsGoal)").font(.caption).foregroundColor(Theme.sub)
                }
                DecimalInput(
                    placeholder: "Nombre de pas (voir app Santé)",
                    value: Binding<Double?>(
                        get: { h.steps == 0 ? nil : Double(h.steps) },
                        set: { v in store.editHabits(date) { $0.steps = Int(v ?? 0) } }
                    ),
                    integer: true
                )
                .id(Fmt.dayKey(date))
                .inputStyle()
                ProgressBar(value: Double(h.steps) / Double(max(1, p.stepsGoal)), color: Theme.green)
            }
        }
    }

    private var checksCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 4) {
                SectionTitle("Discipline")
                Toggle(isOn: bind(\.challengeDone)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Défi du jour (+20 XP)").foregroundColor(.white)
                        Text(Daily.challenge(date)).font(.caption).foregroundColor(Theme.sub)
                    }
                }
                Divider().background(Color.white.opacity(0.1))
                Toggle(isOn: bind(\.noJunk)) {
                    Text("Zéro malbouffe (+10 XP)").foregroundColor(.white)
                }
                Divider().background(Color.white.opacity(0.1))
                Toggle(isOn: bind(\.stretched)) {
                    Text("Étirements / mobilité (+5 XP)").foregroundColor(.white)
                }
            }
            .tint(Theme.accent)
        }
    }

    private var weekCard: some View {
        let c = Store.cal
        let start = c.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let labels = ["L", "M", "M", "J", "V", "S", "D"]
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("Ta semaine")
                HStack {
                    ForEach(0..<7, id: \.self) { i in
                        let d = c.date(byAdding: .day, value: i, to: start) ?? start
                        let ratio = Double(Store.habitXP(store.habits(d), profile: store.data.profile)) / Double(Store.maxHabitXP)
                        let trained = store.sessionDays.contains(Fmt.dayKey(d))
                        VStack(spacing: 6) {
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.08), lineWidth: 5)
                                Circle()
                                    .trim(from: 0, to: min(1, ratio))
                                    .stroke(Theme.gold, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                if trained {
                                    Image(systemName: "dumbbell.fill").font(.system(size: 10)).foregroundColor(Theme.accent)
                                }
                            }
                            .frame(width: 34, height: 34)
                            Text(labels[i])
                                .font(.caption2.weight(.bold))
                                .foregroundColor(c.isDate(d, inSameDayAs: date) ? .white : Theme.sub)
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            if d <= Date() { date = d }
                        }
                    }
                }
            }
        }
    }
}
