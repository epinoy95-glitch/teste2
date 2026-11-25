import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: Store
    @State private var step = 0
    @State private var name = ""
    @State private var goal: Goal = .recompo
    @State private var sex: Sex = .homme
    @State private var age = 20
    @State private var height = 175.0
    @State private var weight: Double? = nil
    @State private var targetWeight: Double? = nil
    @State private var days = 3
    @State private var weekdays: [Int] = [2, 4, 6]
    @State private var time = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()

    private let lastStep = 4

    private var suggestedProgram: Program {
        if days <= 3 { return Library.program("fullbody") }
        if days == 4 { return Library.program("upperlower") }
        return Library.program("ppl")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressBar(value: Double(step + 1) / Double(lastStep + 1))
                    .padding()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch step {
                        case 0: welcomeStep
                        case 1: identityStep
                        case 2: bodyStep
                        case 3: trainingStep
                        default: finalStep
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                HStack(spacing: 12) {
                    if step > 0 {
                        Button("Retour") { withAnimation { step -= 1 } }
                            .buttonStyle(SecondaryButtonStyle())
                            .frame(maxWidth: 120)
                    }
                    Button(step == lastStep ? "C'EST PARTI" : "Suivant") {
                        hideKeyboard()
                        if step == lastStep {
                            finish()
                        } else {
                            withAnimation { step += 1 }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
            .background(Theme.bg.ignoresSafeArea())
            .keyboardDoneButton()
        }
    }

    // MARK: Étapes

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "flame.fill")
                .font(.system(size: 64))
                .foregroundColor(Theme.accent)
                .padding(.top, 30)
            Text("RESTRICTION")
                .font(.system(size: 42, weight: .black))
                .foregroundColor(.white)
            Text("Pas de don. Pas d'énergie spéciale. Pas de raccourci.\nJuste ton corps, ta discipline, et tous les jours un peu plus.")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    feature("dumbbell.fill", "Programmes et suivi de chaque série")
                    feature("crown.fill", "Monte en rang : de Grade 4 à Corps Céleste")
                    feature("flame.fill", "Séries de jours, défis quotidiens, succès")
                    feature("chart.line.uptrend.xyaxis", "Poids, mensurations, photos, records")
                    feature("drop.fill", "Eau, protéines, sommeil, pas")
                    feature("bell.fill", "Rappels qui te bottent le cul")
                }
            }
            Text("Tout reste sur ton téléphone.")
                .font(.caption)
                .foregroundColor(Theme.sub)
        }
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(Theme.accent).frame(width: 24)
            Text(text).foregroundColor(.white).font(.subheadline)
        }
    }

    private var identityStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Qui es-tu ?").font(.largeTitle.weight(.black)).foregroundColor(.white)
            TextField("Ton prénom ou pseudo", text: $name)
                .textInputAutocapitalization(.words)
                .inputStyle()
            Text("Ton objectif principal").font(.headline).foregroundColor(.white)
            ForEach(Goal.allCases) { g in
                Button {
                    goal = g
                    Haptics.tap()
                } label: {
                    HStack {
                        Text(g.rawValue).font(.headline).foregroundColor(.white)
                        Spacer()
                        Image(systemName: goal == g ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(goal == g ? Theme.accent : Theme.sub)
                    }
                    .padding()
                    .background(goal == g ? Theme.accent.opacity(0.15) : Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bodyStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Ton point de départ").font(.largeTitle.weight(.black)).foregroundColor(.white)
            Text("Pas de jugement ici. On note juste d'où tu pars pour mesurer jusqu'où tu iras.")
                .foregroundColor(Theme.sub)
                .fixedSize(horizontal: false, vertical: true)
            Picker("Sexe", selection: $sex) {
                ForEach(Sex.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            Card {
                VStack(spacing: 14) {
                    Stepper("Âge : \(age) ans", value: $age, in: 12...90)
                    Stepper("Taille : \(Int(height)) cm", value: $height, in: 120...230, step: 1)
                    HStack {
                        Text("Poids actuel")
                        Spacer()
                        DecimalInput(placeholder: "kg", value: $weight)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .inputStyle()
                    }
                    HStack {
                        Text("Poids visé (optionnel)")
                        Spacer()
                        DecimalInput(placeholder: "kg", value: $targetWeight)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .inputStyle()
                    }
                }
                .foregroundColor(.white)
            }
        }
    }

    private var trainingStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Ton engagement").font(.largeTitle.weight(.black)).foregroundColor(.white)
            Text("Sois réaliste. Mieux vaut 3 séances tenues que 6 promises.")
                .foregroundColor(Theme.sub)
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    Stepper("Séances par semaine : \(days)", value: $days, in: 1...6)
                    Text("Quels jours ?").font(.subheadline)
                    WeekdayPicker(selection: $weekdays)
                    DatePicker("Heure du rappel", selection: $time, displayedComponents: .hourAndMinute)
                }
                .foregroundColor(.white)
                .tint(Theme.accent)
            }
            Card {
                VStack(alignment: .leading, spacing: 6) {
                    SectionTitle("Programme conseillé")
                    Text(suggestedProgram.name).font(.title3.weight(.black)).foregroundColor(.white)
                    Text(suggestedProgram.description).font(.caption).foregroundColor(Theme.sub)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Tu pourras en changer à tout moment.").font(.caption2).foregroundColor(Theme.sub)
                }
            }
        }
    }

    private var finalStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Le pacte").font(.largeTitle.weight(.black)).foregroundColor(.white)
            Text("À partir d'aujourd'hui :")
                .font(.headline)
                .foregroundColor(.white)
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    feature("checkmark.seal.fill", "Je viens \(days) fois par semaine, même sans envie.")
                    feature("checkmark.seal.fill", "Je note chaque série. Ce qui se mesure progresse.")
                    feature("checkmark.seal.fill", "Les jours sans salle, je fais mon défi.")
                    feature("checkmark.seal.fill", "Je ne me compare qu'à moi d'hier.")
                }
            }
            Text("Rang de départ : Grade 4.\nDestination : Corps Céleste.")
                .font(.title3.weight(.heavy))
                .foregroundColor(Theme.accent)
                .fixedSize(horizontal: false, vertical: true)
            Text("L'app va te demander l'autorisation d'envoyer des notifications : accepte-la, c'est elle qui te rappellera d'y aller.")
                .font(.caption)
                .foregroundColor(Theme.sub)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Fin

    private func finish() {
        var d = store.data
        var p = d.profile
        p.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        p.goal = goal
        p.sex = sex
        p.age = age
        p.heightCm = height
        p.targetWeight = targetWeight
        p.daysPerWeek = days
        p.trainingWeekdays = weekdays.isEmpty ? [2, 4, 6] : weekdays
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        p.reminderHour = comps.hour ?? 18
        p.reminderMinute = comps.minute ?? 0
        p.programId = suggestedProgram.id
        if let w = weight, w > 20 {
            let raw = Int((w * 2.0).rounded())
            p.proteinGoal = max(60, (raw / 5) * 5)
            d.weights.append(WeightEntry(date: Date(), kg: w))
        }
        p.onboarded = true
        d.profile = p
        store.data = d
        Haptics.success()
        Notifs.reschedule(profile: p)
    }
}
