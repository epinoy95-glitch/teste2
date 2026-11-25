import SwiftUI
import UIKit

enum Theme {
    static let bg = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let card2 = Color(red: 0.14, green: 0.14, blue: 0.17)
    static let accent = Color(red: 0.86, green: 0.13, blue: 0.20)
    static let gold = Color(red: 0.96, green: 0.76, blue: 0.27)
    static let green = Color(red: 0.30, green: 0.85, blue: 0.45)
    static let water = Color(red: 0.30, green: 0.70, blue: 1.0)
    static let sub = Color.white.opacity(0.6)
}

// MARK: - Composants

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.heavy))
            .tracking(1.5)
            .foregroundColor(Theme.sub)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.card2.opacity(configuration.isPressed ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ProgressBar: View {
    var value: Double
    var color: Color = Theme.accent
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule().fill(color)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var icon: String? = nil
    var color: Color = .white
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon).foregroundColor(color).font(.subheadline.weight(.bold))
                }
                Text(value)
                    .font(.title3.weight(.black))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundColor(Theme.sub)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct NavRow<Dest: View>: View {
    let title: String
    let icon: String
    var subtitle: String? = nil
    let destination: Dest

    init(_ title: String, icon: String, subtitle: String? = nil, @ViewBuilder destination: () -> Dest) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            RowLabel(title: title, icon: icon, subtitle: subtitle)
        }
        .buttonStyle(.plain)
    }
}

struct RowLabel: View {
    let title: String
    let icon: String
    var subtitle: String? = nil
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundColor(.white)
                if let subtitle = subtitle {
                    Text(subtitle).font(.caption).foregroundColor(Theme.sub)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(Theme.sub)
        }
        .padding()
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Champ numérique basé sur du texte (met à jour la valeur à chaque frappe).
struct DecimalInput: View {
    let placeholder: String
    @Binding var value: Double?
    var integer: Bool = false
    @State private var text: String = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(integer ? .numberPad : .decimalPad)
            .onAppear {
                if let v = value { text = v.clean }
            }
            .onChange(of: text) { t in
                let cleaned = t.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
                value = Double(cleaned)
            }
            .onChange(of: value) { v in
                if v == nil && !text.isEmpty && Double(text.replacingOccurrences(of: ",", with: ".")) != nil {
                    text = ""
                }
            }
    }
}

/// Champ numérique non optionnel (0 = vide).
struct NumberCell: View {
    let placeholder: String
    @Binding var value: Double
    var integer: Bool = false

    var body: some View {
        DecimalInput(
            placeholder: placeholder,
            value: Binding<Double?>(
                get: { value == 0 ? nil : value },
                set: { value = $0 ?? 0 }
            ),
            integer: integer
        )
        .multilineTextAlignment(.center)
        .font(.body.weight(.semibold))
        .foregroundColor(.white)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.card2)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension View {
    func inputStyle() -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .padding(12)
            .background(Theme.card2)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    func keyboardDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { hideKeyboard() }
                    .font(.headline)
            }
        }
    }
}

func intAsDouble(_ b: Binding<Int>) -> Binding<Double> {
    Binding<Double>(
        get: { Double(b.wrappedValue) },
        set: { b.wrappedValue = Int($0.rounded()) }
    )
}

@MainActor
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - Haptique

@MainActor
enum Haptics {
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func tap() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
}

// MARK: - Formatage

extension Double {
    var clean: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        }
        let s = String(format: "%.2f", self)
        var t = s
        while t.hasSuffix("0") { t.removeLast() }
        if t.hasSuffix(".") { t.removeLast() }
        return t
    }
}

enum Fmt {
    static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ d: Date) -> String { dayKeyFormatter.string(from: d) }

    static let day: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    static let shortDay: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "d MMM"
        return f
    }()

    static let longDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    static let dayTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMM · HH:mm"
        return f
    }()

    static func clock(_ sec: Int) -> String {
        let s = max(0, sec)
        let h = s / 3600, m = (s % 3600) / 60, r = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, r) }
        return String(format: "%02d:%02d", m, r)
    }

    static func duration(_ sec: Int) -> String {
        let m = sec / 60
        if m >= 60 { return "\(m / 60) h \(String(format: "%02d", m % 60))" }
        return "\(m) min"
    }

    static func volume(_ kg: Double) -> String {
        if kg >= 1000 { return "\((kg / 1000).clean) t" }
        return "\(Int(kg)) kg"
    }

    static func setText(_ s: SetEntry, unit: ExUnit) -> String {
        let u = unit == .reps ? "" : " \(unit.label)"
        if s.weight > 0 { return "\(s.weight.clean) kg × \(s.reps)\(u)" }
        return unit == .reps ? "\(s.reps) reps" : "\(s.reps)\(u)"
    }

    static func setsSummary(_ sets: [SetEntry], unit: ExUnit) -> String {
        guard !sets.isEmpty else { return "—" }
        return sets.map { setText($0, unit: unit) }.joined(separator: " · ")
    }
}
