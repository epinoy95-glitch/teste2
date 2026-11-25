import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: Store
    @State private var showNoExcuse = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    RankCard()
                    streakRow
                    quoteCard
                    noExcuseButton
                    challengeCard
                    missionsCard
                    nextWorkoutCard
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showNoExcuse) {
                NoExcuseView().environmentObject(store)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Fmt.longDate.string(from: Date()).capitalized)
                .font(.caption.weight(.bold))
                .foregroundColor(Theme.sub)
            Text("Debout, \(store.data.profile.name.isEmpty ? "guerrier" : store.data.profile.name).")
                .font(.system(size: 30, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.top, 8)
    }

    private var streakRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(store.dayStreak)", label: "jours actifs d'affilée", icon: "flame.fill", color: .orange)
            StatTile(value: "\(store.sessionsThisWeek)/\(store.data.profile.daysPerWeek)", label: "séances cette semaine", icon: "dumbbell.fill", color: Theme.accent)
            StatTile(value: "\(store.weekStreak)", label: "semaines validées", icon: "calendar", color: Theme.gold)
        }
    }

    private var quoteCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle("Parole du jour")
                Text("« \(Daily.quote()) »")
                    .font(.title3.weight(.bold))
                    .italic()
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var noExcuseButton: some View {
        Button { showNoExcuse = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "bolt.heart.fill").font(.title)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MODE SANS EXCUSE").font(.headline.weight(.black))
                    Text("Pas motivé ? Appuie ici.").font(.caption).opacity(0.85)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(colors: [Theme.accent, Color(red: 0.35, green: 0.02, blue: 0.06)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var challengeCard: some View {
        let done = store.habits(Date()).challengeDone
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionTitle("Défi du jour")
                    Spacer()
                    Text("+20 XP").font(.caption.weight(.heavy)).foregroundColor(Theme.gold)
                }
                Text(Daily.challenge())
                    .font(.headline)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    store.editHabits(Date()) { $0.challengeDone.toggle() }
                    Haptics.success()
                } label: {
                    Label(done ? "Défi validé" : "Valider le défi", systemImage: done ? "checkmark.seal.fill" : "seal")
                }
                .buttonStyle(PrimaryButtonStyle(color: done ? Theme.green.opacity(0.8) : Theme.accent))
            }
        }
    }

    @ViewBuilder
    private var missionsCard: some View {
        let h = store.habits(Date())
        let p = store.data.profile
        let trained = store.sessionDays.contains(Fmt.dayKey(Date())) || h.challengeDone
        let items: [(String, Bool, String)] = [
            ("Séance ou défi validé", trained, "figure.strengthtraining.traditional"),
            ("Eau : \(h.water)/\(p.waterGoal) verres", h.water >= p.waterGoal, "drop.fill"),
            ("Protéines : \(h.protein)/\(p.proteinGoal) g", h.protein >= p.proteinGoal, "fork.knife"),
            ("Sommeil : \(h.sleep.clean)/\(p.sleepGoal.clean) h", h.sleep >= p.sleepGoal, "bed.double.fill"),
            ("Pas : \(h.steps)/\(p.stepsGoal)", h.steps >= p.stepsGoal, "figure.walk"),
        ]
        let doneCount = items.filter { $0.1 }.count
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionTitle("Missions du jour")
                    Spacer()
                    Text("\(doneCount)/\(items.count)")
                        .font(.caption.weight(.heavy))
                        .foregroundColor(doneCount == items.count ? Theme.green : Theme.sub)
                }
                ForEach(items.indices, id: \.self) { i in
                    HStack(spacing: 10) {
                        Image(systemName: items[i].1 ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(items[i].1 ? Theme.green : Theme.sub)
                        Image(systemName: items[i].2)
                            .frame(width: 22)
                            .foregroundColor(Theme.sub)
                        Text(items[i].0)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .strikethrough(items[i].1, color: Theme.sub)
                        Spacer()
                    }
                }
                Text("Coche tes habitudes dans l'onglet Hygiène.")
                    .font(.caption2)
                    .foregroundColor(Theme.sub)
            }
        }
    }

    @ViewBuilder
    private var nextWorkoutCard: some View {
        let day = store.nextProgramDay
        let prog = store.currentProgram
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("Prochaine séance")
                Text(day.name)
                    .font(.title2.weight(.black))
                    .foregroundColor(.white)
                Text("\(prog.name) · \(day.items.count) exercices")
                    .font(.caption)
                    .foregroundColor(Theme.sub)
                Text(day.items.map { Library.exercise($0.ex).name }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundColor(Theme.sub)
                    .lineLimit(3)
                Button { store.start(day: day) } label: {
                    Label("Lancer la séance", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

struct RankCard: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let xp = store.totalXP
        let lvl = Levels.level(for: xp)
        let rank = Ranks.forLevel(lvl)
        let cur = Levels.xpFor(level: lvl)
        let nxt = Levels.xpFor(level: lvl + 1)
        let prog = Double(xp - cur) / Double(max(1, nxt - cur))
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(rank.color.opacity(0.18)).frame(width: 64, height: 64)
                    Circle().stroke(rank.color.opacity(0.6), lineWidth: 2).frame(width: 64, height: 64)
                    Image(systemName: rank.icon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(rank.color)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(rank.name.uppercased())
                        .font(.headline.weight(.black))
                        .foregroundColor(rank.color)
                    Text("Niveau \(lvl) · \(xp) XP")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    ProgressBar(value: prog, color: rank.color)
                    Text("\(nxt - xp) XP avant le niveau \(lvl + 1)")
                        .font(.caption)
                        .foregroundColor(Theme.sub)
                }
            }
        }
    }
}

// MARK: - Mode Sans Excuse

struct NoExcuseView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var quote = Quotes.random
    @State private var runCircuit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Theme.accent)
                        .padding(.top, 10)
                    Text(quote)
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        withAnimation { quote = Quotes.random }
                        Haptics.tap()
                    } label: {
                        Label("Encore une", systemImage: "arrow.clockwise")
                    }
                    .foregroundColor(Theme.sub)

                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle("Pas le temps ? Pas de salle ?")
                            Text(Circuits.noExcuse.name)
                                .font(.title3.weight(.black))
                                .foregroundColor(.white)
                            Text("7 exercices · 40 s d'effort / 20 s de repos · zéro matériel")
                                .font(.caption)
                                .foregroundColor(Theme.sub)
                            ForEach(Circuits.noExcuse.moves, id: \.self) { m in
                                HStack {
                                    Image(systemName: "bolt.fill").foregroundColor(Theme.accent).font(.caption)
                                    Text(m).foregroundColor(.white).font(.subheadline)
                                }
                            }
                        }
                    }

                    Button { runCircuit = true } label: {
                        Label("LANCER LE CIRCUIT", systemImage: "play.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Text("Terminer le circuit valide ton défi du jour (+20 XP) et garde ta série en vie.")
                        .font(.caption)
                        .foregroundColor(Theme.sub)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $runCircuit) {
                HIITRunnerView(title: Circuits.noExcuse.name, phases: Circuits.noExcuse.phases) {
                    store.editHabits(Date()) { $0.challengeDone = true }
                }
            }
        }
    }
}

// MARK: - Minuteur d'intervalles

struct HIITRunnerView: View {
    let title: String
    let phases: [HIITPhase]
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var remaining = 0
    @State private var running = true
    @State private var finished = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var phase: HIITPhase {
        phases.isEmpty ? HIITPhase(name: "—", seconds: 0, isWork: false) : phases[min(index, phases.count - 1)]
    }

    private var nextName: String? {
        index + 1 < phases.count ? phases[index + 1].name : nil
    }

    private var bgColor: Color {
        if finished { return Theme.bg }
        return phase.isWork ? Theme.accent : Color(red: 0.10, green: 0.12, blue: 0.16)
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack(spacing: 22) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.title2.weight(.bold)).foregroundColor(.white)
                    }
                    Spacer()
                    Text(title).font(.headline).foregroundColor(.white.opacity(0.85))
                    Spacer()
                    Text("\(min(index + 1, max(phases.count, 1)))/\(phases.count)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                if finished {
                    Image(systemName: "trophy.fill").font(.system(size: 80)).foregroundColor(Theme.gold)
                    Text("TERMINÉ")
                        .font(.system(size: 44, weight: .black))
                        .foregroundColor(.white)
                    Text("Tu l'as fait. Pas d'excuse, que des résultats.")
                        .foregroundColor(Theme.sub)
                        .multilineTextAlignment(.center)
                    Button("Fermer") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    Text(phase.isWork ? "GO" : "REPOS")
                        .font(.headline.weight(.black))
                        .tracking(4)
                        .foregroundColor(.white.opacity(0.8))
                    Text(phase.name)
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("\(remaining)")
                        .font(.system(size: 130, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    if let n = nextName {
                        Text("Ensuite : \(n)")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    HStack(spacing: 40) {
                        Button { back() } label: {
                            Image(systemName: "backward.fill").font(.title)
                        }
                        Button { running.toggle() } label: {
                            Image(systemName: running ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 70))
                        }
                        Button { advance() } label: {
                            Image(systemName: "forward.fill").font(.title)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.top, 10)
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            remaining = phases.first?.seconds ?? 0
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(ticker) { _ in tick() }
    }

    private func tick() {
        guard running, !finished, !phases.isEmpty else { return }
        if remaining > 1 {
            remaining -= 1
            if remaining <= 3 { Haptics.tap() }
        } else {
            advance()
        }
    }

    private func advance() {
        guard !phases.isEmpty else { return }
        if index + 1 < phases.count {
            index += 1
            remaining = phases[index].seconds
            Haptics.heavy()
        } else if !finished {
            finished = true
            Haptics.success()
            onComplete()
        }
    }

    private func back() {
        guard !phases.isEmpty else { return }
        if index > 0 { index -= 1 }
        remaining = phases[index].seconds
    }
}
