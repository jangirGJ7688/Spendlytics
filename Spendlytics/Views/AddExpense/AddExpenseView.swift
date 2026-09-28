import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddExpenseViewModel
    let onSave: (ExpenseDTO) -> Void
    private let isEditing: Bool
    private let categoryColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    init(expenseService: ExpenseService, expense: Expense? = nil, onSave: @escaping (ExpenseDTO) -> Void) {
        self.onSave = onSave
        self.isEditing = expense != nil
        _viewModel = StateObject(wrappedValue: AddExpenseViewModel(expenseService: expenseService, expense: expense))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SpendlyticsStyle.canvas.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 23) {
                        heading
                        amountEntry
                        detailsSection
                        categorySection
                        dateSection
                    }
                    .padding(20).padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task {
                        if let expense = await viewModel.saveExpense() {
                            onSave(expense)
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 9) {
                        if viewModel.isSaving { ProgressView().tint(.white) }
                        Text(viewModel.isSaving ? "Saving…" : isEditing ? "Save changes" : "Save expense")
                        if !viewModel.isSaving { Image(systemName: "arrow.right").font(.system(size: 13, weight: .semibold)) }
                    }
                }
                .buttonStyle(PrimaryActionStyle())
                .disabled(!viewModel.isValid || viewModel.isSaving)
                .opacity(!viewModel.isValid || viewModel.isSaving ? 0.55 : 1)
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
                .background(.ultraThinMaterial)
            }
            .alert("Unable to Save Expense", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var heading: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(isEditing ? "UPDATE DETAILS" : "NEW TRANSACTION")
                    .font(PoppinsFont.medium(9)).tracking(1.4).foregroundStyle(SpendlyticsStyle.accent)
                Text(isEditing ? "Edit expense" : "Add expense")
                    .font(PoppinsFont.bold(25)).foregroundStyle(SpendlyticsStyle.ink)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SpendlyticsStyle.muted).frame(width: 36, height: 36)
                    .background(.white, in: Circle()).overlay(Circle().stroke(SpendlyticsStyle.line, lineWidth: 1))
            }
            .accessibilityLabel("Close")
        }
    }

    private var amountEntry: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("HOW MUCH?").font(PoppinsFont.medium(9)).tracking(1.2).foregroundStyle(SpendlyticsStyle.muted)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("₹").font(PoppinsFont.medium(25)).foregroundStyle(SpendlyticsStyle.muted)
                TextField("0.00", text: $viewModel.amount)
                    .font(PoppinsFont.semibold(34)).foregroundStyle(SpendlyticsStyle.ink)
                    .keyboardType(.decimalPad).minimumScaleFactor(0.7)
            }
            Rectangle().fill(SpendlyticsStyle.line).frame(height: 1)
        }
        .padding(18).background(.white, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel("WHAT WAS IT FOR?")
            HStack(spacing: 11) {
                Image(systemName: "text.alignleft").foregroundStyle(SpendlyticsStyle.muted).frame(width: 19)
                TextField("e.g. Coffee with friends", text: $viewModel.title).font(PoppinsFont.regular(13))
            }
            .padding(.horizontal, 15).frame(height: 52).background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("CHOOSE A CATEGORY")
            LazyVGrid(columns: categoryColumns, spacing: 9) {
                ForEach(ExpenseCategory.allCases) { category in
                    let isSelected = viewModel.category == category.rawValue
                    let tint = SpendlyticsStyle.categoryColor(category.rawValue)
                    Button {
                        withAnimation(.snappy(duration: 0.18)) { viewModel.category = category.rawValue }
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: SpendlyticsStyle.categorySymbol(category.rawValue))
                                .font(.system(size: 16, weight: .medium)).foregroundStyle(isSelected ? .white : tint)
                                .frame(width: 36, height: 36).background(isSelected ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Text(category.displayName).font(PoppinsFont.medium(10)).foregroundStyle(isSelected ? SpendlyticsStyle.ink : SpendlyticsStyle.muted).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(isSelected ? tint.opacity(0.08) : .white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isSelected ? tint.opacity(0.55) : SpendlyticsStyle.line, lineWidth: isSelected ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("WHEN DID IT HAPPEN?")
            HStack(spacing: 10) {
                Image(systemName: "calendar").foregroundStyle(SpendlyticsStyle.accent)
                    .frame(width: 36, height: 36).background(SpendlyticsStyle.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Expense date").font(PoppinsFont.medium(11)).foregroundStyle(SpendlyticsStyle.ink)
                    Text(viewModel.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(PoppinsFont.regular(10)).foregroundStyle(SpendlyticsStyle.muted)
                }
                Spacer()
                DatePicker("Expense date", selection: $viewModel.date, displayedComponents: .date)
                    .labelsHidden().tint(SpendlyticsStyle.accent).accessibilityLabel("Expense date")
            }
            .padding(12).background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
        }
    }

    private func sectionLabel(_ label: String) -> some View {
        Text(label).font(PoppinsFont.medium(9)).tracking(1.1).foregroundStyle(SpendlyticsStyle.muted)
    }
}
