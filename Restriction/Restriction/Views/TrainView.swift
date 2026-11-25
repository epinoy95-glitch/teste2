import SwiftUI
import Charts

struct TrainView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let prog = store.currentProgram
                    let next = store.nextProgramDay

                    Card {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitle("Programme actuel")
                            Text(prog.name).font(.title2.weight(.black)).foregroundColor(.white)
                            Text("\(prog.level) · \(prog.days)").font(.caption).foregroundColor(Theme.sub)
                            Text(prog.description).font(.subheadline).foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    SectionTitle("Séances du programme")
                    ForEach(prog.workouts) { d in
                        Button { store.start(day: d) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 8) {
                                        Text(d.name).font(.headline).foregroundColor(.white)
                                        if d.id == next.id {
                                            Text("SUIVANTE")
                                                .font(.caption2.weight(.black))
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(Theme.accent)
                                                .foregroundColor(.white)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(d.items.map { Library.exercise($0.ex).name }.joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundColor(Theme.sub)
                                        .lineLimit(2)
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

                    Button { store.startEmpty() } label: {
                        Label("Séance libre", systemImage: "plus")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    SectionTitle("Outils")
                    NavRow("Changer de programme", icon: "list.bullet.rectangle.fill", subtitle: "\(Library.programs.count) programmes disponibles") {
                        ProgramsView()
                    }
                    NavRow("Bibliothèque d'exercices", icon: "books.vertical.fill", subtitle: "Technique et progression") {
                        ExerciseLibraryView()
                    }
                    NavRow("Historique", icon: "clock.arrow.circlepath", subtitle: "\(store.data.sessions.count) séances") {
                        HistoryView()
                    }
                    NavRow("Minuteur HIIT / circuits", icon: "timer", subtitle: "Tabata, finishers, cardio") {
                        HIITSetupView()
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Entraînement")
        }
    }
}

// MARK: - Séance en cours

struct ActiveWorkoutView: View {
    @EnvironmentObject var store: Store
    let template: WorkoutTemplate

    @State private var logs: [ExerciseLog] = []
    @State private var loaded = false
    @State private var startDate = Date()
    @State private var now = Date()
    @State private var restEnd: Date? = nil
    @State private var showPicker = false
    @State private var confirmQuit = false
    @State private var emptyAlert = false
    @State private var result: WorkoutSession? = nil
    @State private var levelBefore = 1
    @State private var bestScores: [String: Double] = [:]

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let r = result {
                WorkoutSummaryView(session: r, levelBefore: levelBefore) {
                    store.pendingWorkout = nil
                }
            } else {
                workoutContent
            }
        }
        .onAppear {
            guard !loaded else { return }
            logs = template.logs
            startDate = Date()
            levelBefore = store.level
            refreshBest()
            loaded = true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            Notifs.cancelRest()
        }
    }

    private var workoutContent: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 14) {
                        header
                        ForEach($logs) { $log in
                            ExerciseLogCard(
                                log: $log,
                                previous: store.lastLog(for: log.exerciseId),
                                bestScore: bestScores[log.exerciseId] ?? 0,
                                onSetDone: { rest in startRest(rest) },
                                onDelete: {
                                    let id = log.id
                                    withAnimation { logs.removeAll { $0.id == id } }
                                }
                            )
                        }
                        Button { showPicker = true } label: {
                            Label("Ajouter un exercice", systemImage: "plus")
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button { finish() } label: {
                            Label("Terminer la séance", systemImage: "flag.checkered")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Spacer(minLength: 110)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)

                if let end = restEnd {
                    restBanner(end: end)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Quitter") { confirmQuit = true }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminer") { finish() }.fontWeight(.bold)
                }
            }
            .keyboardDoneButton()
            .sheet(isPresented: $showPicker) {
                ExercisePickerView { exId in
                    logs.append(store.newLog(for: exId))
                    refreshBest()
                }
            }
            .alert("Abandonner la séance ?", isPresented: $confirmQuit) {
                Button("Abandonner", role: .destructive) { store.pendingWorkout = nil }
                Button("Continuer", role: .cancel) {}
            } message: {
                Text("Rien ne sera enregistré. Un guerrier finit ce qu'il commence.")
            }
            .alert("Aucune série validée", isPresented: $emptyAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Coche au moins une série (✓) pour enregistrer ta séance.")
            }
            .onReceive(ticker) { t in
                now = t
                if let end = restEnd, t >= end {
                    restEnd = nil
                    Haptics.success()
                }
            }
        }
    }

    private var header: some View {
        let done = logs.reduce(0) { $0 + $1.doneSets.count }
        let total = logs.reduce(0) { $0 + $1.sets.count }
        return HStack(spacing: 10) {
            StatTile(value: Fmt.clock(Int(now.timeIntervalSince(startDate))), label: "durée", icon: "stopwatch", color: Theme.accent)
            StatTile(value: "\(done)/\(total)", label: "séries", icon: "checkmark.square", color: Theme.green)
            StatTile(value: Fmt.volume(logs.reduce(0) { $0 + $1.volume }), label: "volume", icon: "scalemass", color: Theme.gold)
        }
    }

    private func restBanner(end: Date) -> some View {
        let remaining = max(0, Int(end.timeIntervalSince(now).rounded(.up)))
        return HStack(spacing: 12) {
            Image(systemName: "timer").font(.title2).foregroundColor(Theme.accent)
            VStack(alignment: .leading, spacing: 0) {
                Text("REPOS").font(.caption2.weight(.black)).foregroundColor(Theme.sub)
                Text(Fmt.clock(remaining))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            Spacer()
            Button("-15") { adjustRest(-15) }.buttonStyle(.bordered)
            Button("+15") { adjustRest(15) }.buttonStyle(.bordered)
            Button {
                restEnd = nil
                Notifs.cancelRest()
            } label: {
                Image(systemName: "forward.end.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .tint(Theme.accent)
        .padding()
        .background(Theme.card2)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
        .padding()
    }

    private func startRest(_ seconds: Int) {
        guard seconds > 0 else { return }
        restEnd = Date().addingTimeInterval(TimeInterval(seconds))
        Notifs.scheduleRest(seconds: seconds)
    }

    private func adjustRest(_ delta: Int) {
        guard let end = restEnd else { return }
        let newEnd = end.addingTimeInterval(TimeInterval(delta))
        if newEnd <= Date() {
            restEnd = nil
            Notifs.cancelRest()
        } else {
            restEnd = newEnd
            Notifs.scheduleRest(seconds: Int(newEnd.timeIntervalSinceNow))
        }
    }

    private func refreshBest() {
        var d: [String: Double] = [:]
        for l in logs { d[l.exerciseId] = store.bestScore(for: l.exerciseId) }
        bestScores = d
    }

    private func finish() {
        hideKeyboard()
        let done = logs.reduce(0) { $0 + $1.doneSets.count }
        guard done > 0 else {
            emptyAlert = true
            return
        }
        Notifs.cancelRest()
        restEnd = nil
        let s = store.finishWorkout(template: template, logs: logs, start: startDate)
        Haptics.success()
        withAnimation { result = s }
    }
}

struct ExerciseLogCard: View {
    @Binding var log: ExerciseLog
    let previous: ExerciseLog?
    let bestScore: Double
    var onSetDone: (Int) -> Void
    var onDelete: () -> Void

    @State private var showInfo = false

    var body: some View {
        let ex = Library.exercise(log.exerciseId)
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(ex.name).font(.headline.weight(.heavy)).foregroundColor(.white)
                        Text("\(ex.muscle.rawValue) · objectif \(log.targetReps.isEmpty ? "libre" : log.targetReps) · repos \(log.rest) s")
                            .font(.caption)
                            .foregroundColor(Theme.sub)
                    }
                    Spacer()
                    Menu {
                        Button { showInfo = true } label: { Label("Technique", systemImage: "info.circle") }
                        Button { log.rest = max(15, log.rest - 15) } label: { Label("Repos -15 s", systemImage: "minus") }
                        Button { log.rest += 15 } label: { Label("Repos +15 s", systemImage: "plus") }
                        Button(role: .destructive) { onDelete() } label: { Label("Retirer l'exercice", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill").font(.title2).foregroundColor(Theme.sub)
                    }
                }

                if let p = previous {
                    Text("Dernière fois : \(Fmt.setsSummary(p.doneSets, unit: ex.unit))")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Theme.gold)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Text("SÉRIE").frame(width: 44, alignment: .leading)
                    Text(ex.bodyweight ? "LEST KG" : "KG").frame(maxWidth: .infinity)
                    Text(ex.unit.label.uppercased()).frame(maxWidth: .infinity)
                    Text("OK").frame(width: 44)
                }
                .font(.caption2.weight(.heavy))
                .foregroundColor(Theme.sub)

                ForEach($log.sets) { $entry in
                    let n = (log.sets.firstIndex(where: { $0.id == entry.id }) ?? 0) + 1
                    let isPR = entry.done && bestScore > 0 && setScore(entry) > bestScore
                    HStack {
                        HStack(spacing: 2) {
                            Text("\(n)").font(.subheadline.weight(.bold)).foregroundColor(.white)
                            if isPR {
                                Image(systemName: "trophy.fill").font(.caption2).foregroundColor(Theme.gold)
                            }
                        }
                        .frame(width: 44, alignment: .leading)
                        NumberCell(placeholder: ex.bodyweight ? "PDC" : "kg", value: $entry.weight)
                        NumberCell(placeholder: ex.unit.label, value: intAsDouble($entry.reps), integer: true)
                        Button {
                            entry.done.toggle()
                            if entry.done {
                                Haptics.tap()
                                onSetDone(log.rest)
                            }
                        } label: {
                            Image(systemName: entry.done ? "checkmark.square.fill" : "square")
                                .font(.title2)
                                .foregroundColor(entry.done ? Theme.green : Theme.sub)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44)
                    }
                    .padding(.vertical, 3)
                    .background(entry.done ? Theme.green.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack {
                    Button {
                        let last = log.sets.last
                        log.sets.append(SetEntry(reps: last?.reps ?? 10, weight: last?.weight ?? 0))
                    } label: {
                        Label("Série", systemImage: "plus")
                    }
                    Spacer()
                    if log.sets.count > 1 {
                        Button {
                            log.sets.removeLast()
                        } label: {
                            Label("Retirer", systemImage: "minus")
                        }
                    }
                }
                .font(.subheadline.weight(.bold))
                .foregroundColor(Theme.accent)
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showInfo) {
            ExerciseInfoSheet(exercise: ex)
        }
    }
}

struct ExerciseInfoSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(exercise.name).font(.title.weight(.black)).foregroundColor(.white)
                    HStack {
                        Label(exercise.muscle.rawValue, systemImage: "figure.strengthtraining.traditional")
                        Label(exercise.equipment, systemImage: "wrench.and.screwdriver")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.sub)
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle("Technique")
                            Text(exercise.tips).foregroundColor(.white).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle("Règle de progression")
                            Text("Quand tu réussis toutes tes séries en haut de la fourchette de répétitions, ajoute du poids la séance suivante (+2,5 kg en général, +1 à 2 kg pour les petits muscles).")
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Bilan de séance

struct WorkoutSummaryView: View {
    @EnvironmentObject var store: Store
    let session: WorkoutSession
    let levelBefore: Int
    var onClose: () -> Void

    @State private var feeling = 3
    @State private var quote = Quotes.random

    private let emojis = ["😵", "😮‍💨", "😐", "💪", "🔥"]

    var body: some View {
        let levelNow = store.level
        let rankBefore = Ranks.forLevel(levelBefore)
        let rankNow = Ranks.forLevel(levelNow)
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Theme.accent)
                    .padding(.top, 40)
                Text("SÉANCE TERMINÉE")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(.white)
                Text("+\(session.xp) XP")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundColor(Theme.gold)

                if levelNow > levelBefore {
                    Card {
                        VStack(spacing: 6) {
                            Text("NIVEAU \(levelNow) !")
                                .font(.title.weight(.black))
                                .foregroundColor(rankNow.color)
                            if rankNow.id != rankBefore.id {
                                Text("Nouveau rang : \(rankNow.name)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(rankNow.lore)
                                    .font(.caption)
                                    .foregroundColor(Theme.sub)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                HStack(spacing: 10) {
                    StatTile(value: Fmt.duration(session.durationSec), label: "durée", icon: "stopwatch", color: Theme.accent)
                    StatTile(value: Fmt.volume(session.volume), label: "volume", icon: "scalemass", color: Theme.gold)
                    StatTile(value: "\(session.setsCount)", label: "séries", icon: "checkmark.square", color: Theme.green)
                }

                if !session.prs.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle("Nouveaux records 🏆")
                            ForEach(session.prs, id: \.self) { id in
                                HStack {
                                    Image(systemName: "trophy.fill").foregroundColor(Theme.gold)
                                    Text(Library.exercise(id).name).foregroundColor(.white)
                                }
                            }
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle("Comment tu te sens ?")
                        HStack {
                            ForEach(1...5, id: \.self) { i in
                                Button {
                                    feeling = i
                                    Haptics.tap()
                                } label: {
                                    Text(emojis[i - 1])
                                        .font(.system(size: 34))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(feeling == i ? Theme.accent.opacity(0.35) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Text("« \(quote) »")
                    .font(.headline)
                    .italic()
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    store.updateSession(session.id) { $0.feeling = feeling }
                    onClose()
                } label: {
                    Text("Retour")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 30)
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
    }
}

// MARK: - Choix d'exercice

struct MuscleChips: View {
    @Binding var selection: Muscle?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil)
                ForEach(Muscle.allCases) { m in chip(m) }
            }
            .padding(.horizontal)
        }
    }

    private func chip(_ m: Muscle?) -> some View {
        let sel = selection == m
        return Button { selection = m } label: {
            Text(m?.rawValue ?? "Tous")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(sel ? Theme.accent : Theme.card2)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ExercisePickerView: View {
    var onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var muscle: Muscle? = nil

    private var filtered: [Exercise] {
        Library.exercises.filter {
            (muscle == nil || $0.muscle == muscle) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MuscleChips(selection: $muscle).padding(.vertical, 8)
                List(filtered) { ex in
                    Button {
                        onPick(ex.id)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name).foregroundColor(.white)
                                Text("\(ex.muscle.rawValue) · \(ex.equipment)").font(.caption).foregroundColor(Theme.sub)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").foregroundColor(Theme.accent).font(.title3)
                        }
                    }
                    .listRowBackground(Theme.card)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Theme.bg.ignoresSafeArea())
            .searchable(text: $search, prompt: "Rechercher un exercice")
            .navigationTitle("Ajouter un exercice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
            }
        }
    }
}

// MARK: - Bibliothèque

struct ExerciseLibraryView: View {
    @State private var search = ""
    @State private var muscle: Muscle? = nil

    private var filtered: [Exercise] {
        Library.exercises.filter {
            (muscle == nil || $0.muscle == muscle) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MuscleChips(selection: $muscle).padding(.vertical, 8)
            List {
                ForEach(Muscle.allCases) { m in
                    let items = filtered.filter { $0.muscle == m }
                    if !items.isEmpty {
                        Section(m.rawValue) {
                            ForEach(items) { ex in
                                NavigationLink {
                                    ExerciseDetailView(exercise: ex)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ex.name).foregroundColor(.white)
                                        Text(ex.equipment).font(.caption).foregroundColor(Theme.sub)
                                    }
                                }
                                .listRowBackground(Theme.card)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .background(Theme.bg.ignoresSafeArea())
        .searchable(text: $search, prompt: "Rechercher")
        .navigationTitle("Exercices")
    }
}

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ExerciseDetailView: View {
    @EnvironmentObject var store: Store
    let exercise: Exercise

    private var points: [ChartPoint] {
        store.data.sessions.sorted { $0.date < $1.date }.compactMap { s in
            guard let l = s.exercises.first(where: { $0.exerciseId == exercise.id }) else { return nil }
            let vals = l.doneSets.map { $0.weight > 0 ? e1RM(weight: $0.weight, reps: $0.reps) : Double($0.reps) }
            guard let best = vals.max() else { return nil }
            return ChartPoint(date: s.date, value: best)
        }
    }

    var body: some View {
        let rec = store.records.first { $0.exerciseId == exercise.id }
        let pts = points
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(exercise.name).font(.title.weight(.black)).foregroundColor(.white)
                Text("\(exercise.muscle.rawValue) · \(exercise.equipment)").font(.caption).foregroundColor(Theme.sub)
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle("Technique")
                        Text(exercise.tips).foregroundColor(.white).fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let r = rec {
                    Card {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionTitle("Ton record")
                            Text(Fmt.setText(r.set, unit: exercise.unit))
                                .font(.title2.weight(.black))
                                .foregroundColor(Theme.gold)
                            if r.set.weight > 0 {
                                Text("1RM estimé : \(e1RM(weight: r.set.weight, reps: r.set.reps).clean) kg")
                                    .font(.caption).foregroundColor(Theme.sub)
                            }
                            Text("Le \(Fmt.day.string(from: r.date))").font(.caption).foregroundColor(Theme.sub)
                        }
                    }
                }
                if pts.count >= 2 {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(pts.contains { $0.value > 0 } && (rec?.set.weight ?? 0) > 0 ? "Progression (1RM estimé)" : "Progression (répétitions)")
                            Chart(pts) { p in
                                LineMark(x: .value("Date", p.date), y: .value("Valeur", p.value))
                                    .foregroundStyle(Theme.accent)
                                    .interpolationMethod(.catmullRom)
                                PointMark(x: .value("Date", p.date), y: .value("Valeur", p.value))
                                    .foregroundStyle(Theme.accent)
                            }
                            .frame(height: 200)
                        }
                    }
                } else {
                    Text("Fais cet exercice au moins 2 fois pour voir ta courbe de progression.")
                        .font(.caption).foregroundColor(Theme.sub)
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Programmes

struct ProgramsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(Library.programs) { p in
                    let selected = store.data.profile.programId == p.id
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(p.name).font(.title3.weight(.black)).foregroundColor(.white)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.green)
                                }
                            }
                            Text("\(p.level) · \(p.days)").font(.caption.weight(.bold)).foregroundColor(Theme.accent)
                            Text(p.description).font(.subheadline).foregroundColor(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                            ForEach(p.workouts) { d in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(d.name).font(.caption.weight(.heavy)).foregroundColor(.white)
                                    Text(d.items.map { "\(Library.exercise($0.ex).name) \($0.sets)×\($0.reps)" }.joined(separator: " · "))
                                        .font(.caption2)
                                        .foregroundColor(Theme.sub)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Button {
                                store.data.profile.programId = p.id
                                Haptics.success()
                            } label: {
                                Text(selected ? "Programme actuel" : "Choisir ce programme")
                            }
                            .buttonStyle(PrimaryButtonStyle(color: selected ? Theme.card2 : Theme.accent))
                            .disabled(selected)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Programmes")
    }
}

// MARK: - Historique

struct HistoryView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            if store.data.sessions.isEmpty {
                Text("Aucune séance pour l'instant. Ta légende commence aujourd'hui.")
                    .foregroundColor(Theme.sub)
                    .listRowBackground(Theme.card)
            }
            ForEach(store.sessionsSorted) { s in
                NavigationLink {
                    SessionDetailView(sessionId: s.id)
                } label: {
                    SessionRow(session: s)
                }
                .listRowBackground(Theme.card)
            }
            .onDelete { idx in
                let items = store.sessionsSorted
                for i in idx { store.deleteSession(items[i].id) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Historique")
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.name).font(.headline).foregroundColor(.white)
                if !session.prs.isEmpty {
                    Image(systemName: "trophy.fill").foregroundColor(Theme.gold).font(.caption)
                }
                Spacer()
                Text("+\(session.xp) XP").font(.caption.weight(.heavy)).foregroundColor(Theme.gold)
            }
            Text(Fmt.dayTime.string(from: session.date).capitalized).font(.caption).foregroundColor(Theme.sub)
            Text("\(Fmt.duration(session.durationSec)) · \(session.setsCount) séries · \(Fmt.volume(session.volume))")
                .font(.caption)
                .foregroundColor(Theme.sub)
        }
        .padding(.vertical, 4)
    }
}

struct SessionDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let sessionId: UUID
    @State private var confirmDelete = false

    var body: some View {
        if let s = store.data.sessions.first(where: { $0.id == sessionId }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(s.name).font(.title.weight(.black)).foregroundColor(.white)
                    Text(Fmt.dayTime.string(from: s.date).capitalized).font(.caption).foregroundColor(Theme.sub)
                    HStack(spacing: 10) {
                        StatTile(value: Fmt.duration(s.durationSec), label: "durée")
                        StatTile(value: Fmt.volume(s.volume), label: "volume")
                        StatTile(value: "+\(s.xp)", label: "XP")
                    }
                    ForEach(s.exercises) { l in
                        let ex = Library.exercise(l.exerciseId)
                        Card {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(ex.name).font(.headline).foregroundColor(.white)
                                    if s.prs.contains(l.exerciseId) {
                                        Text("RECORD").font(.caption2.weight(.black)).foregroundColor(Theme.gold)
                                    }
                                }
                                ForEach(Array(l.doneSets.enumerated()), id: \.offset) { i, st in
                                    Text("Série \(i + 1) : \(Fmt.setText(st, unit: ex.unit))")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.sub)
                                }
                            }
                        }
                    }
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Supprimer la séance", systemImage: "trash")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .alert("Supprimer cette séance ?", isPresented: $confirmDelete) {
                Button("Supprimer", role: .destructive) {
                    store.deleteSession(sessionId)
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            }
        } else {
            Text("Séance supprimée.").foregroundColor(Theme.sub)
        }
    }
}
