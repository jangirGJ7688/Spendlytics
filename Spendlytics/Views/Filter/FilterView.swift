//
//  FilterView.swift
//  Spendlytics
//
//  Created by Ganpat Jangir on 14/03/26.
//


import SwiftUI

struct FilterView: View {
    
    @ObservedObject var viewModel: HomeViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var minPrice: String = ""
    @State private var maxPrice: String = ""
    
    var body: some View {
        
        NavigationStack {
            
            Form {
                
                categorySection
                
                dateSection
                
                priceSection
            }
            .navigationTitle("Filters")
            .toolbar {
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") {
                        viewModel.clearFilters()
                        minPrice = ""
                        maxPrice = ""
                    }
                    .disabled(!viewModel.hasActiveFilters)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        applyPriceFilter()
                        dismiss()
                    }
                }
            }
        }
    }
}

extension FilterView {
    
    var categorySection: some View {
        
        Section("Category") {
            
            Picker("Category", selection: $viewModel.filter.selectedCategory) {
                
                Text("All").tag(String?.none)
                
                ForEach(viewModel.categories, id: \.self) {
                    Text($0).tag(Optional($0))
                }
            }
        }
    }
}

extension FilterView {
    
    var dateSection: some View {
        
        Section("Date Range") {
            
            DatePicker(
                "Start Date",
                selection: Binding(
                    get: { viewModel.filter.startDate ?? Date() },
                    set: { viewModel.filter.startDate = $0 }
                ),
                displayedComponents: .date
            )
            
            DatePicker(
                "End Date",
                selection: Binding(
                    get: { viewModel.filter.endDate ?? Date() },
                    set: { viewModel.filter.endDate = $0 }
                ),
                displayedComponents: .date
            )
        }
    }
}

extension FilterView {
    
    var priceSection: some View {
        
        Section("Price Range") {
            
            TextField("Min Price", text: $minPrice)
                .keyboardType(.decimalPad)
            
            TextField("Max Price", text: $maxPrice)
                .keyboardType(.decimalPad)
        }
    }
    
    func applyPriceFilter() {
        
        viewModel.filter.minPrice = Double(minPrice)
        viewModel.filter.maxPrice = Double(maxPrice)
    }
}
