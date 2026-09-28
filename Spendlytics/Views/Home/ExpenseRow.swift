import SwiftUI

struct ExpenseRow: View {
    let expense: Expense
    var isDeleting = false

    private var categoryTint: Color { SpendlyticsStyle.categoryColor(expense.category) }

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: SpendlyticsStyle.categorySymbol(expense.category))
                .font(.system(size: 17, weight: .medium)).foregroundStyle(categoryTint)
                .frame(width: 46, height: 46).background(categoryTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name).font(PoppinsFont.semibold(13)).foregroundStyle(SpendlyticsStyle.ink).lineLimit(1)
                HStack(spacing: 5) {
                    Text(ExpenseCategory.displayName(for: expense.category))
                    Circle().frame(width: 3, height: 3)
                    Text(expense.date.formatted(.dateTime.month(.abbreviated).day()))
                }
                .font(PoppinsFont.regular(10)).foregroundStyle(SpendlyticsStyle.muted)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 4) {
                Text("−₹\(expense.amount, specifier: "%.2f")")
                    .font(PoppinsFont.semibold(13)).foregroundStyle(SpendlyticsStyle.ink).lineLimit(1).minimumScaleFactor(0.8)
                Text(expense.date.formatted(.dateTime.hour().minute()))
                    .font(PoppinsFont.regular(9)).foregroundStyle(SpendlyticsStyle.muted)
            }

            if isDeleting { ProgressView().tint(SpendlyticsStyle.accent).frame(width: 18).padding(.leading, 2) }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 19, style: .continuous).stroke(SpendlyticsStyle.line.opacity(0.75), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
    }
}
