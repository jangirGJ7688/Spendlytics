import SwiftUI
import CoreText

enum SpendlyticsStyle {
    static let ink = Color(red: 0.10, green: 0.15, blue: 0.25)
    static let muted = Color(red: 0.48, green: 0.53, blue: 0.62)
    static let canvas = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let accent = Color(red: 0.30, green: 0.34, blue: 0.94)
    static let mint = Color(red: 0.33, green: 0.78, blue: 0.66)
    static let line = Color(red: 0.89, green: 0.91, blue: 0.94)
    static let card = Color.white

    static let categoryColors: [Color] = [
        Color(red: 0.97, green: 0.58, blue: 0.39),
        Color(red: 0.34, green: 0.65, blue: 0.90),
        Color(red: 0.68, green: 0.50, blue: 0.88),
        Color(red: 0.95, green: 0.72, blue: 0.34),
        Color(red: 0.92, green: 0.43, blue: 0.55),
        Color(red: 0.36, green: 0.72, blue: 0.60),
        Color(red: 0.32, green: 0.72, blue: 0.77),
        Color(red: 0.84, green: 0.61, blue: 0.38),
        Color(red: 0.52, green: 0.61, blue: 0.79),
        Color(red: 0.34, green: 0.69, blue: 0.54),
        Color(red: 0.55, green: 0.61, blue: 0.68)
    ]

    static func categoryColor(_ category: String) -> Color {
        let index = ExpenseCategory.allCases.firstIndex(where: { $0.rawValue == category }) ?? 10
        return categoryColors[index % categoryColors.count]
    }

    static func categorySymbol(_ category: String) -> String {
        switch ExpenseCategory(rawValue: category) {
        case .food: "fork.knife"
        case .travel: "airplane"
        case .shopping: "bag"
        case .bills: "doc.text"
        case .entertainment: "play.tv"
        case .health: "heart"
        case .education: "book.closed"
        case .groceries: "basket"
        case .rent: "house"
        case .salary: "banknote"
        case .other, .none: "circle.grid.2x2"
        }
    }
}

enum PoppinsFont {
    static func regular(_ size: CGFloat) -> Font { .custom("Poppins-Regular", size: size, relativeTo: .body) }
    static func medium(_ size: CGFloat) -> Font { .custom("Poppins-Medium", size: size, relativeTo: .body) }
    static func semibold(_ size: CGFloat) -> Font { .custom("Poppins-SemiBold", size: size, relativeTo: .body) }
    static func bold(_ size: CGFloat) -> Font { .custom("Poppins-Bold", size: size, relativeTo: .body) }
}

enum PoppinsRegistration {
    static func registerBundledFonts() {
        ["Poppins-Regular", "Poppins-Medium", "Poppins-SemiBold", "Poppins-Bold"].forEach { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Assets/Fonts")
                    ?? Bundle.main.url(forResource: name, withExtension: "ttf") else { return }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

struct SoftCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(SpendlyticsStyle.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(SpendlyticsStyle.line.opacity(0.7), lineWidth: 1))
    }
}

struct PrimaryActionStyle: ButtonStyle {
    var color: Color = SpendlyticsStyle.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PoppinsFont.semibold(15))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct IconActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(SpendlyticsStyle.ink)
            .frame(width: 44, height: 44)
            .background(.white)
            .clipShape(Circle())
            .overlay(Circle().stroke(SpendlyticsStyle.line, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
