import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    @StateObject private var viewModel: HomeViewModel
    private let expenseService: ExpenseService
    private let authManager: AuthManager
    @State private var showAddExpense = false
    @State private var showFilter = false
    @State private var showDeleteAlert = false
    @State private var showLogoutConfirmation = false
    @State private var showAccountDeletionConfirmation = false
    @State private var selectedExpense: Expense?
    @State private var expenseToEdit: Expense?

    init(expenseService: ExpenseService, authManager: AuthManager) {
        self.expenseService = expenseService
        self.authManager = authManager
        _viewModel = StateObject(wrappedValue: HomeViewModel(expenseService: expenseService))
        let ownerScope = authManager.cacheScope ?? ""
        _expenses = Query(filter: #Predicate<Expense> { $0.ownerScope == ownerScope }, sort: \Expense.date, order: .reverse)
    }

    private var visibleExpenses: [Expense] { viewModel.filteredExpenses(from: expenses) }
    private var categoryOptions: [String] { Array(Set(expenses.map(\.category))).sorted() }

    var body: some View {
        NavigationStack {
            ZStack {
                SpendlyticsStyle.canvas.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        balanceOverview
                        searchField
                        categoryPicker
                        activitySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
                .refreshable { await refreshExpenses() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .overlay {
                if viewModel.isLoading && expenses.isEmpty {
                    ProgressView().tint(SpendlyticsStyle.accent)
                }
            }
            .task { await refreshExpenses() }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(expenseService: expenseService) { savedExpense in
                    context.insert(Expense(remoteID: savedExpense.id, ownerScope: authManager.cacheScope, name: savedExpense.name, category: savedExpense.category, date: savedExpense.date, value: savedExpense.amount))
                }
            }
            .sheet(item: $expenseToEdit) { expense in
                AddExpenseView(expenseService: expenseService, expense: expense) { updatedExpense in
                    expense.name = updatedExpense.name
                    expense.category = updatedExpense.category
                    expense.amount = updatedExpense.amount
                    expense.date = updatedExpense.date
                }
            }
            .sheet(isPresented: $showFilter) { FilterView(viewModel: viewModel) }
            .navigationDestination(for: String.self) { route in
                if route == "summary" { SummaryView(expenses: expenses) }
            }
            .confirmationDialog("Delete Expense", isPresented: $showDeleteAlert, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let expense = selectedExpense { Task { await viewModel.deleteExpense(expense, context: context) } }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this expense?")
            }
            .confirmationDialog("Sign Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { Task { await signOut() } }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You can sign back in at any time.")
            }
            .confirmationDialog("Delete Account", isPresented: $showAccountDeletionConfirmation, titleVisibility: .visible) {
                Button("Delete Account", role: .destructive) { Task { await deleteAccount() } }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes your account and cannot be undone.")
            }
            .alert("Expenses", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(PoppinsFont.medium(10)).tracking(1.5).foregroundStyle(SpendlyticsStyle.muted)
                Text("Your money,\nin focus.")
                    .font(PoppinsFont.bold(27)).lineSpacing(-3).foregroundStyle(SpendlyticsStyle.ink)
            }
            Spacer()
            Menu {
                Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) { showLogoutConfirmation = true }
                Button("Delete Account", systemImage: "person.crop.circle.badge.xmark", role: .destructive) { showAccountDeletionConfirmation = true }
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 39)).symbolRenderingMode(.palette)
                    .foregroundStyle(SpendlyticsStyle.accent, .white)
                    .padding(2).background(SpendlyticsStyle.accent.opacity(0.12), in: Circle())
            }
            .accessibilityLabel("Account")
        }
    }

    private var balanceOverview: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Label("ALL-TIME SPENDING", systemImage: "chart.line.uptrend.xyaxis")
                    .font(PoppinsFont.medium(10)).tracking(1.1).foregroundStyle(.white.opacity(0.76))
                Spacer()
                NavigationLink(value: "summary") {
                    Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white).frame(width: 34, height: 34)
                        .background(.white.opacity(0.14), in: Circle())
                }
                .accessibilityLabel("View spending summary")
            }
            Text("₹\(viewModel.totalExpense(from: expenses), specifier: "%.2f")")
                .font(PoppinsFont.bold(34)).foregroundStyle(.white).minimumScaleFactor(0.7).lineLimit(1)
            Rectangle().fill(.white.opacity(0.18)).frame(height: 1)
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    Image(systemName: "sun.max.fill").font(.system(size: 14)).foregroundStyle(SpendlyticsStyle.mint)
                        .frame(width: 34, height: 34).background(.white.opacity(0.14), in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Spent today").font(PoppinsFont.regular(11)).foregroundStyle(.white.opacity(0.72))
                        Text("₹\(viewModel.todayExpense(from: expenses), specifier: "%.2f")").font(PoppinsFont.semibold(15)).foregroundStyle(.white)
                    }
                }
                Spacer()
                Button { showAddExpense = true } label: {
                    Label("Add expense", systemImage: "plus").font(PoppinsFont.semibold(12))
                        .foregroundStyle(SpendlyticsStyle.ink).padding(.horizontal, 14).padding(.vertical, 11)
                        .background(.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(LinearGradient(colors: [Color(red: 0.28, green: 0.32, blue: 0.89), Color(red: 0.43, green: 0.36, blue: 0.91)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle().fill(.white.opacity(0.045)).frame(width: 155, height: 155).offset(x: 54, y: -78).clipped()
                .allowsHitTesting(false)
        }
        .shadow(color: SpendlyticsStyle.accent.opacity(0.2), radius: 18, x: 0, y: 10)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(SpendlyticsStyle.muted)
            TextField("Search expenses", text: $viewModel.filter.searchText)
                .font(PoppinsFont.regular(13)).autocorrectionDisabled()
            if !viewModel.filter.searchText.isEmpty {
                Button { viewModel.filter.searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(SpendlyticsStyle.muted) }
            }
            Button { showFilter = true } label: {
                Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "slider.horizontal.3")
                    .font(.system(size: 17, weight: .medium)).foregroundStyle(SpendlyticsStyle.accent)
            }
            .accessibilityLabel("Filter expenses")
        }
        .padding(.horizontal, 15).frame(height: 50)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                categoryChip(title: "All", value: nil)
                ForEach(categoryOptions, id: \.self) { category in
                    categoryChip(title: ExpenseCategory.displayName(for: category), value: category)
                }
            }
        }
        .contentMargins(.trailing, 2)
    }

    private func categoryChip(title: String, value: String?) -> some View {
        let isSelected = viewModel.filter.selectedCategory == value
        return Button {
            withAnimation(.snappy(duration: 0.2)) { viewModel.filter.selectedCategory = value }
        } label: {
            Text(title).font(PoppinsFont.medium(12))
                .foregroundStyle(isSelected ? .white : SpendlyticsStyle.muted)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(isSelected ? SpendlyticsStyle.ink : .white, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? .clear : SpendlyticsStyle.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Recent activity").font(PoppinsFont.semibold(19)).foregroundStyle(SpendlyticsStyle.ink)
                    Text("Your latest spending, at a glance").font(PoppinsFont.regular(11)).foregroundStyle(SpendlyticsStyle.muted)
                }
                Spacer()
                Text("\(visibleExpenses.count) items").font(PoppinsFont.medium(10)).foregroundStyle(SpendlyticsStyle.muted)
            }

            if visibleExpenses.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(visibleExpenses) { expense in
                        ExpenseRow(expense: expense, isDeleting: viewModel.deletingExpenseID == expense.id)
                            .onTapGesture { expenseToEdit = expense }
                            .onLongPressGesture { selectedExpense = expense; showDeleteAlert = true }
                            .onAppear {
                                if viewModel.shouldLoadNextPage(for: expense), let ownerScope = authManager.cacheScope {
                                    Task { await viewModel.loadNextPage(context: context, ownerScope: ownerScope) }
                                }
                            }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        SoftCard {
            VStack(spacing: 12) {
                Image(systemName: expenses.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 27, weight: .light)).foregroundStyle(SpendlyticsStyle.accent)
                    .frame(width: 58, height: 58).background(SpendlyticsStyle.accent.opacity(0.09), in: Circle())
                Text(expenses.isEmpty ? "A fresh start" : "Nothing found")
                    .font(PoppinsFont.semibold(16)).foregroundStyle(SpendlyticsStyle.ink)
                Text(expenses.isEmpty ? "Add your first expense to see your spending take shape." : "Try another search or adjust your filters.")
                    .font(PoppinsFont.regular(12)).foregroundStyle(SpendlyticsStyle.muted).multilineTextAlignment(.center)
                if expenses.isEmpty {
                    Button("Add your first expense") { showAddExpense = true }
                        .font(PoppinsFont.semibold(12)).foregroundStyle(SpendlyticsStyle.accent).padding(.top, 3)
                }
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
        }
    }

    private func refreshExpenses() async {
        if let ownerScope = authManager.cacheScope { await viewModel.loadExpenses(context: context, ownerScope: ownerScope) }
    }

    private func signOut() async {
        let ownerScope = authManager.cacheScope
        await authManager.logout()
        clearCachedExpenses(ownerScope: ownerScope)
    }

    private func deleteAccount() async {
        let ownerScope = authManager.cacheScope
        do {
            try await authManager.deleteAccount()
            clearCachedExpenses(ownerScope: ownerScope)
        } catch {
            viewModel.errorMessage = APIError.map(error).userMessage
        }
    }

    private func clearCachedExpenses(ownerScope: String?) {
        guard let ownerScope else { return }
        let descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.ownerScope == ownerScope })
        guard let cachedExpenses = try? context.fetch(descriptor) else { return }
        cachedExpenses.forEach { context.delete($0) }
    }
}
