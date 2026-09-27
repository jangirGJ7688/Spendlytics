//
//  HomeView.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    
    @Environment(\.modelContext) private var context
    
    @Query
    private var expenses: [Expense]
    
    @StateObject private var viewModel: HomeViewModel
    private let expenseService: ExpenseService
    private let authManager: AuthManager
    @State private var showAddExpense = false
    @State private var showFilter = false
    @State private var showDeleteAlert = false
    @State private var selectedExpense: Expense?
    @State private var expenseToEdit: Expense?

    init(expenseService: ExpenseService, authManager: AuthManager) {
        self.expenseService = expenseService
        self.authManager = authManager
        _viewModel = StateObject(wrappedValue: HomeViewModel(expenseService: expenseService))
        let ownerScope = authManager.cacheScope ?? ""
        _expenses = Query(filter: #Predicate<Expense> { $0.ownerScope == ownerScope }, sort: \Expense.date, order: .reverse)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                VStack(spacing: 20) {
                    
                    summarySection
                    
                    expenseList
                }
                .padding()
            }
            .searchable(
                text: $viewModel.filter.searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search expenses"
            )
            .navigationTitle("Expenses")
            .overlay {
                if viewModel.isLoading && expenses.isEmpty { ProgressView() }
            }
            .task {
                if let ownerScope = authManager.cacheScope {
                    await viewModel.loadExpenses(context: context, ownerScope: ownerScope)
                }
            }
            .refreshable {
                if let ownerScope = authManager.cacheScope {
                    await viewModel.loadExpenses(context: context, ownerScope: ownerScope)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
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
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilter = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilter) {
                FilterView(viewModel: viewModel)
            }
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: "summary") {
                        Image(systemName: "chart.pie")
                    }
                }
            }
            .navigationDestination(for: String.self) { route in
                if route == "summary" {
                    SummaryView(expenses: expenses)
                }
            }
            .confirmationDialog("Delete Expense", isPresented: $showDeleteAlert, titleVisibility: .visible) {
                
                Button("Delete", role: .destructive) {
                    if let expense = selectedExpense {
                        Task { await viewModel.deleteExpense(expense, context: context) }
                    }
                }
                
                Button("Cancel", role: .cancel) { }
                
            } message: {
                Text("Are you sure you want to delete this expense?")
            }
            .alert("Expenses", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                            authManager.signOut()
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
        }
    }
}

extension HomeView {
    
    private var summarySection: some View {
        
        HStack(spacing: 16) {
            
            SummaryCard(
                title: "Total",
                amount: viewModel.totalExpense(from: expenses),
                color: .blue
            )
            
            SummaryCard(
                title: "Today",
                amount: viewModel.todayExpense(from: expenses),
                color: .green
            )
        }
    }
}

extension HomeView {
    
    private var expenseList: some View {
        
        LazyVStack(spacing: 12) {
            
            ForEach(viewModel.filteredExpenses(from: expenses)) { expense in
                
                ExpenseRow(expense: expense, isDeleting: viewModel.deletingExpenseID == expense.id)
                    .onTapGesture {
                        expenseToEdit = expense
                    }
                    .onLongPressGesture {
                            selectedExpense = expense
                            showDeleteAlert = true
                        }
                    .onAppear {
                        if viewModel.shouldLoadNextPage(for: expense) {
                            if let ownerScope = authManager.cacheScope {
                                Task { await viewModel.loadNextPage(context: context, ownerScope: ownerScope) }
                            }
                        }
                    }
            }
        }
    }
}
