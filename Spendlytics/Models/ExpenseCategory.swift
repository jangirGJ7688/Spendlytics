import Foundation

enum ExpenseCategory: String, CaseIterable, Identifiable {
    case food = "FOOD"
    case travel = "TRAVEL"
    case shopping = "SHOPPING"
    case bills = "BILLS"
    case entertainment = "ENTERTAINMENT"
    case health = "HEALTH"
    case education = "EDUCATION"
    case groceries = "GROCERIES"
    case rent = "RENT"
    case salary = "SALARY"
    case other = "OTHER"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .food: "Food"
        case .travel: "Travel"
        case .shopping: "Shopping"
        case .bills: "Bills"
        case .entertainment: "Entertainment"
        case .health: "Health"
        case .education: "Education"
        case .groceries: "Groceries"
        case .rent: "Rent"
        case .salary: "Salary"
        case .other: "Other"
        }
    }

    static func displayName(for rawValue: String) -> String {
        ExpenseCategory(rawValue: rawValue)?.displayName ?? rawValue
    }
}
