import Foundation

struct ExpenseDTO: Codable, Identifiable {
    let id: Int64
    let name: String
    let category: String
    let amount: Double
    let date: Date

    enum CodingKeys: String, CodingKey { case id, name, title, category, amount, date, expenseDate }

    init(id: Int64, name: String, category: String, amount: Double, date: Date) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int64.self, forKey: .id)
        name = try values.decodeIfPresent(String.self, forKey: .name)
            ?? values.decode(String.self, forKey: .title)
        category = try values.decode(String.self, forKey: .category)
        amount = try values.decode(Double.self, forKey: .amount)
        let rawDate = try values.decodeIfPresent(String.self, forKey: .date)
            ?? values.decode(String.self, forKey: .expenseDate)
        if let dateValue = Self.dateFormatter.date(from: rawDate) ?? ISO8601DateFormatter().date(from: rawDate) {
            date = dateValue
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: values, debugDescription: "Invalid expense date")
        }
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(name, forKey: .title)
        try values.encode(category, forKey: .category)
        try values.encode(amount, forKey: .amount)
        try values.encode(Self.dateFormatter.string(from: date), forKey: .expenseDate)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct ExpensePage: Decodable {
    let content: [ExpenseDTO]
    let page: Int
    let size: Int
    let totalElements: Int
    let totalPages: Int
    let first: Bool
    let last: Bool
}
