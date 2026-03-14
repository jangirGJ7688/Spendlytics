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
    
    @Query(sort: \Expense.date, order: .reverse)
    private var expenses: [Expense]
    
    @StateObject private var viewModel = HomeViewModel()
    @State private var showAddExpense = false
    @State private var showFilter = false
    @State private var showDeleteAlert = false
    @State private var selectedExpense: Expense?
    
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
                AddExpenseView()
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
            .alert("Delete Expense", isPresented: $showDeleteAlert) {
                
                Button("Delete", role: .destructive) {
                    if let expense = selectedExpense {
                        viewModel.deleteExpense(expense, context: context)
                    }
                }
                
                Button("Cancel", role: .cancel) { }
                
            } message: {
                Text("Are you sure you want to delete this expense?")
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
                
                ExpenseRow(expense: expense)
                    .onLongPressGesture {
                            selectedExpense = expense
                            showDeleteAlert = true
                        }
            }
        }
    }
}


