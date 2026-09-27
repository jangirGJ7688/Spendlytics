import Foundation

@MainActor
final class ExpenseService {
    private let client: APIClient
    private let encoder = JSONEncoder()

    init(client: APIClient) { self.client = client }

    func fetchExpenses(page: Int = 0, size: Int = 10) async throws -> ExpensePage {
        try await client.send("/expenses?page=\(page)&size=\(size)")
    }

    func createExpense(name: String, category: String, amount: Double, date: Date) async throws -> ExpenseDTO {
        let body = try encoder.encode(ExpenseDTO(id: 0, name: name, category: category, amount: amount, date: date))
        return try await client.send("/expenses", method: "POST", body: body)
    }

    func updateExpense(id: Int64, name: String, category: String, amount: Double, date: Date) async throws -> ExpenseDTO {
        let body = try encoder.encode(ExpenseDTO(id: id, name: name, category: category, amount: amount, date: date))
        return try await client.send("/expenses/\(id)", method: "PUT", body: body)
    }

    func deleteExpense(id: Int64) async throws {
        try await client.sendWithoutResponse("/expenses/\(id)", method: "DELETE")
    }
}
