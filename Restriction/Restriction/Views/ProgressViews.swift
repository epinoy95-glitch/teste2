import SwiftUI
import Charts
import PhotosUI

enum ProgressSection: String, CaseIterable, Identifiable {
    case poids = "Poids"
    case mesures = "Mesures"
    case photos = "Photos"
    case records = "Records"
    case stats = "Stats"
    var id: String { rawValue }
}

struct ProgressTabView: View {
    @State private var section: ProgressSection = .poids

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Section", selection: $section) {
                        ForEach(ProgressSection.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch section {
                    case .poids: WeightSection()
                    case .mesures: MeasuresSection()
                    case .photos: PhotosSection()
                    case .records: RecordsSection()
                    case .stats: StatsSection()
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Progrès")
            .keyboardDoneButton()
        }
    }
}

// MARK: - Poids

struct WeightSection: View {
    @EnvironmentObject var store: Store
    @State private var input: Double? = nil
    @State private var date = Date()

    var body: some View {
        let ws = store.weightsSorted
        let target = store.data.profile.targetWeight
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                StatTile(value: ws.last.map { "\($0.kg.clean) kg" } ?? "—", label: "actuel", icon: "scalemass.fill", color: Theme.accent)
                StatTile(value: diffText(ws), label: "depuis le début", icon: "arrow.up.arrow.down", color: Theme.gold)
                StatTile(value: target.map { "\($0.clean) kg" } ?? "—", label: "objectif", icon: "target", color: Theme.green)
            }

            if let t = target, let cur = ws.last?.kg {
                let remaining = cur - t
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        SectionTitle("Objectif")
                        Text(abs(remaining) < 0.1
                             ? "Objectif atteint. Fixe-toi le suivant."
                             : "Encore \(abs(remaining).clean) kg à \(remaining > 0 ? "perdre" : "prendre").")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            }

            if ws.count >= 2 {
                let minV = (ws.map { $0.kg }.min() ?? 0) - 2
                let maxV = (ws.map { $0.kg }.max() ?? 100) + 2
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle("Évolution")
                        Chart(ws) { w in
                            LineMark(x: .value("Date", w.date), y: .value("Poids", w.kg))
                                .foregroundStyle(Theme.accent)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", w.date), y: .value("Poids", w.kg))
                                .foregroundStyle(Theme.accent)
                            if let t = target {
                                RuleMark(y: .value("Objectif", t))
                                    .foregroundStyle(Theme.green.opacity(0.7))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                            }
                        }
                        .chartYScale(domain: min(minV, (target ?? minV) - 1)...max(maxV, (target ?? maxV) + 1))
                        .frame(height: 220)
                    }
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Nouvelle pesée")
                    HStack {
                        DecimalInput(placeholder: "Poids (kg)", value: $input)
                            .inputStyle()
                        DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                    }
                    Button {
                        if let v = input, v > 20, v < 400 {
                            store.addWeight(v, date: date)
                            input = nil
                            date = Date()
                            hideKeyboard()
                            Haptics.success()
                        }
                    } label: {
                        Text("Enregistrer")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Text("Astuce : pèse-toi le matin à jeun, après être passé aux toilettes. Regarde la tendance, pas un jour isolé.")
                        .font(.caption2)
                        .foregroundColor(Theme.sub)
                }
            }

            if !ws.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle("Historique")
                        ForEach(Array(ws.reversed())) { w in
                            HStack {
                                Text(Fmt.day.string(from: w.date)).foregroundColor(Theme.sub).font(.subheadline)
                                Spacer()
                                Text("\(w.kg.clean) kg").font(.subheadline.weight(.bold)).foregroundColor(.white)
                                Button { store.deleteWeight(w.id) } label: {
                                    Image(systemName: "trash").foregroundColor(Theme.sub)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 8)
                            }
                        }
                    }
                }
            }
        }
    }

    private func diffText(_ ws: [WeightEntry]) -> String {
        guard let f = ws.first, let l = ws.last, ws.count >= 2 else { return "—" }
        let d = l.kg - f.kg
        return (d > 0 ? "+" : "") + "\(d.clean) kg"
    }
}

// MARK: - Mensurations

struct MeasuresSection: View {
    @EnvironmentObject var store: Store
    @State private var waist: Double? = nil
    @State private var chest: Double? = nil
    @State private var arm: Double? = nil
    @State private var thigh: Double? = nil
    @State private var hips: Double? = nil

    var body: some View {
        let ms = store.measuresSorted
        let waistPoints = ms.compactMap { m in m.waist.map { ChartPoint(date: m.date, value: $0) } }
        VStack(spacing: 16) {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Nouvelles mesures (cm)")
                    measureField("Tour de taille", $waist)
                    measureField("Poitrine", $chest)
                    measureField("Bras (contracté)", $arm)
                    measureField("Cuisse", $thigh)
                    measureField("Hanches", $hips)
                    Button {
                        guard waist != nil || chest != nil || arm != nil || thigh != nil || hips != nil else { return }
                        store.data.measures.append(MeasureEntry(date: Date(), waist: waist, chest: chest, arm: arm, thigh: thigh, hips: hips))
                        waist = nil; chest = nil; arm = nil; thigh = nil; hips = nil
                        hideKeyboard()
                        Haptics.success()
                    } label: {
                        Text("Enregistrer")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Text("Le tour de taille est le meilleur indicateur de perte de gras. Mesure au niveau du nombril.")
                        .font(.caption2)
                        .foregroundColor(Theme.sub)
                }
            }

            if waistPoints.count >= 2 {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle("Tour de taille")
                        Chart(waistPoints) { p in
                            LineMark(x: .value("Date", p.date), y: .value("cm", p.value))
                                .foregroundStyle(Theme.gold)
                            PointMark(x: .value("Date", p.date), y: .value("cm", p.value))
                                .foregroundStyle(Theme.gold)
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 180)
                    }
                }
            }

            ForEach(Array(ms.reversed())) { m in
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(Fmt.day.string(from: m.date)).font(.headline).foregroundColor(.white)
                            Spacer()
                            Button { store.deleteMeasure(m.id) } label: {
                                Image(systemName: "trash").foregroundColor(Theme.sub)
                            }
                            .buttonStyle(.plain)
                        }
                        measureLine("Taille", m.waist)
                        measureLine("Poitrine", m.chest)
                        measureLine("Bras", m.arm)
                        measureLine("Cuisse", m.thigh)
                        measureLine("Hanches", m.hips)
                    }
                }
            }
        }
    }

    private func measureField(_ label: String, _ value: Binding<Double?>) -> some View {
        HStack {
            Text(label).foregroundColor(.white).font(.subheadline)
            Spacer()
            DecimalInput(placeholder: "cm", value: value)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .inputStyle()
        }
    }

    @ViewBuilder
    private func measureLine(_ label: String, _ v: Double?) -> some View {
        if let v = v {
            HStack {
                Text(label).foregroundColor(Theme.sub).font(.subheadline)
                Spacer()
                Text("\(v.clean) cm").foregroundColor(.white).font(.subheadline.weight(.semibold))
            }
        }
    }
}

// MARK: - Photos

struct PhotosSection: View {
    @EnvironmentObject var store: Store
    @State private var item: PhotosPickerItem? = nil
    @State private var selected: PhotoEntry? = nil
    @State private var loading = false

    var body: some View {
        let photos = store.data.photos.sorted { $0.date < $1.date }
        VStack(spacing: 16) {
            PhotosPicker(selection: $item, matching: .images) {
                Label(loading ? "Import..." : "Ajouter une photo", systemImage: "camera.fill")
                    .font(.headline.weight(.heavy))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            Text("Tes photos restent uniquement sur ton téléphone. Prends-les toujours au même endroit, même lumière, même pose.")
                .font(.caption)
                .foregroundColor(Theme.sub)
                .multilineTextAlignment(.center)

            if photos.count >= 2, let first = photos.first, let last = photos.last {
                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle("Avant / Après")
                        HStack(spacing: 8) {
                            photoTile(first, height: 220)
                            photoTile(last, height: 220)
                        }
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(photos.reversed())) { p in
                    photoTile(p, height: 140)
                        .onTapGesture { selected = p }
                        .contextMenu {
                            Button(role: .destructive) { store.deletePhoto(p) } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                }
            }

            if photos.isEmpty {
                Text("Aucune photo. Prends ta photo « avant » aujourd'hui : dans 3 mois, tu me remercieras.")
                    .font(.subheadline)
                    .foregroundColor(Theme.sub)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .onChange(of: item) { newItem in
            guard let newItem = newItem else { return }
            loading = true
            Task {
                let d = try? await newItem.loadTransferable(type: Data.self)
                await MainActor.run {
                    if let d = d { store.addPhoto(d) }
                    item = nil
                    loading = false
                }
            }
        }
        .sheet(item: $selected) { p in
            PhotoViewer(photo: p).environmentObject(store)
        }
    }

    private func photoTile(_ p: PhotoEntry, height: CGFloat) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                Group {
                    if let img = store.image(for: p) {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else {
                        Theme.card2
                    }
                }
            )
            .clipped()
            .overlay(alignment: .bottomLeading) {
                Text(Fmt.shortDay.string(from: p.date))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct PhotoViewer: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let photo: PhotoEntry

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let img = store.image(for: photo) {
                    Image(uiImage: img).resizable().scaledToFit()
                }
            }
            .navigationTitle(Fmt.day.string(from: photo.date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        store.deletePhoto(photo)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - Records

struct RecordsSection: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let recs = store.records
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                StatTile(value: "\(store.prCount)", label: "records battus", icon: "trophy.fill", color: Theme.gold)
                StatTile(value: "\(recs.count)", label: "exercices suivis", icon: "list.bullet", color: Theme.accent)
            }
            if recs.isEmpty {
                Text("Termine des séances pour voir tes records ici.")
                    .foregroundColor(Theme.sub)
                    .padding()
            }
            ForEach(recs) { r in
                let ex = Library.exercise(r.exerciseId)
                NavigationLink {
                    ExerciseDetailView(exercise: ex)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ex.name).font(.headline).foregroundColor(.white)
                            Text(Fmt.day.string(from: r.date)).font(.caption).foregroundColor(Theme.sub)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(Fmt.setText(r.set, unit: ex.unit)).font(.headline.weight(.black)).foregroundColor(Theme.gold)
                            if r.set.weight > 0 {
                                Text("1RM ≈ \(e1RM(weight: r.set.weight, reps: r.set.reps).clean) kg")
                                    .font(.caption)
                                    .foregroundColor(Theme.sub)
                            }
                        }
                    }
                    .padding()
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Stats

struct StatsSection: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let weeks = store.weekStats(10)
        let muscles = store.muscleStats(days: 30)
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatTile(value: "\(store.data.sessions.count)", label: "séances au total", icon: "dumbbell.fill", color: Theme.accent)
                StatTile(value: Fmt.volume(store.totalVolume), label: "soulevés au total", icon: "scalemass.fill", color: Theme.gold)
                StatTile(value: Fmt.duration(store.totalDuration), label: "passées à la salle", icon: "clock.fill", color: Theme.water)
                StatTile(value: "\(store.totalSets)", label: "séries terminées", icon: "checkmark.square.fill", color: Theme.green)
                StatTile(value: "\(store.bestDayStreak)", label: "meilleure série de jours", icon: "flame.fill", color: .orange)
                StatTile(value: "\(store.totalXP)", label: "XP total", icon: "star.fill", color: Theme.gold)
            }

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("Régularité (16 semaines)")
                    Heatmap()
                    HStack(spacing: 12) {
                        legend(Theme.accent, "Séance")
                        legend(Theme.accent.opacity(0.4), "Défi")
                        legend(Color.white.opacity(0.07), "Rien")
                    }
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle("Séances par semaine")
                    Chart(weeks) { w in
                        BarMark(x: .value("Semaine", w.id, unit: .weekOfYear), y: .value("Séances", w.sessions))
                            .foregroundStyle(w.sessions >= store.data.profile.daysPerWeek ? Theme.green : Theme.accent)
                            .cornerRadius(4)
                    }
                    .frame(height: 180)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle("Volume par semaine (kg)")
                    Chart(weeks) { w in
                        BarMark(x: .value("Semaine", w.id, unit: .weekOfYear), y: .value("Volume", w.volume))
                            .foregroundStyle(Theme.gold)
                            .cornerRadius(4)
                    }
                    .frame(height: 180)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle("Séries par muscle (30 jours)")
                    Chart(muscles) { m in
                        BarMark(x: .value("Séries", m.sets), y: .value("Muscle", m.id))
                            .foregroundStyle(Theme.accent)
                            .cornerRadius(4)
                    }
                    .frame(height: 220)
                    Text("Vise 10 à 20 séries par semaine et par muscle pour progresser.")
                        .font(.caption2)
                        .foregroundColor(Theme.sub)
                }
            }
        }
    }

    private func legend(_ c: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3).fill(c).frame(width: 12, height: 12)
            Text(label).font(.caption2).foregroundColor(Theme.sub)
        }
    }
}

struct Heatmap: View {
    @EnvironmentObject var store: Store
    private let weeks = 16

    var body: some View {
        let c = Store.cal
        let days = store.sessionDays
        let today = Date()
        let thisWeek = c.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let start = c.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisWeek) ?? thisWeek
        HStack(alignment: .top, spacing: 4) {
            VStack(spacing: 4) {
                ForEach(["L", "M", "M", "J", "V", "S", "D"].indices, id: \.self) { i in
                    Text(["L", "M", "M", "J", "V", "S", "D"][i])
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.sub)
                        .frame(width: 12, height: 14)
                }
            }
            ForEach(0..<weeks, id: \.self) { w in
                VStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { d in
                        let date = c.date(byAdding: .day, value: w * 7 + d, to: start) ?? start
                        let key = Fmt.dayKey(date)
                        let trained = days.contains(key)
                        let challenge = store.data.habits[key]?.challengeDone ?? false
                        RoundedRectangle(cornerRadius: 3)
                            .fill(date > today ? Color.clear
                                  : (trained ? Theme.accent
                                     : (challenge ? Theme.accent.opacity(0.4) : Color.white.opacity(0.07))))
                            .frame(maxWidth: .infinity)
                            .frame(height: 14)
                    }
                }
            }
        }
    }
}
