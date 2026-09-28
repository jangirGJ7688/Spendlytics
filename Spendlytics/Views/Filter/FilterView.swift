import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var minPrice = ""
    @State private var maxPrice = ""
    @State private var filterByDate = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                SpendlyticsStyle.canvas.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 23) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MAKE IT YOURS").font(PoppinsFont.medium(9)).tracking(1.4).foregroundStyle(SpendlyticsStyle.accent)
                            Text("Find an expense").font(PoppinsFont.bold(25)).foregroundStyle(SpendlyticsStyle.ink)
                            Text("Narrow your list with a few quick filters.").font(PoppinsFont.regular(12)).foregroundStyle(SpendlyticsStyle.muted)
                        }
                        categorySection
                        dateSection
                        priceSection
                    }
                    .padding(20).padding(.bottom, 26)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Reset") { clearFilters() }
                        .font(PoppinsFont.semibold(13)).foregroundStyle(SpendlyticsStyle.ink)
                        .frame(width: 92, height: 50).background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
                    Button {
                        applyFilters()
                        dismiss()
                    } label: { Text("Show results") }
                        .buttonStyle(PrimaryActionStyle())
                }
                .padding(.horizontal, 20).padding(.top, 11).padding(.bottom, 8).background(.ultraThinMaterial)
            }
            .onAppear {
                minPrice = viewModel.filter.minPrice.map { String($0) } ?? ""
                maxPrice = viewModel.filter.maxPrice.map { String($0) } ?? ""
                filterByDate = viewModel.filter.startDate != nil || viewModel.filter.endDate != nil
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading("Category", detail: "Choose one or browse everything")
            LazyVGrid(columns: columns, spacing: 8) {
                filterCategory(title: "All", value: nil)
                ForEach(viewModel.categories, id: \.self) { category in
                    filterCategory(title: ExpenseCategory.displayName(for: category), value: category)
                }
            }
        }
    }

    private func filterCategory(title: String, value: String?) -> some View {
        let selected = viewModel.filter.selectedCategory == value
        return Button { viewModel.filter.selectedCategory = value } label: {
            Text(title).font(PoppinsFont.medium(10)).lineLimit(1).minimumScaleFactor(0.8)
                .foregroundStyle(selected ? .white : SpendlyticsStyle.muted)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(selected ? SpendlyticsStyle.ink : .white, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(selected ? .clear : SpendlyticsStyle.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading("Date range", detail: "Filter by when you spent")
            VStack(spacing: 0) {
                Toggle(isOn: $filterByDate.animation(.snappy(duration: 0.2))) {
                    Label("Set a date range", systemImage: "calendar")
                        .font(PoppinsFont.medium(12)).foregroundStyle(SpendlyticsStyle.ink)
                }
                .tint(SpendlyticsStyle.accent).padding(15)
                if filterByDate {
                    Rectangle().fill(SpendlyticsStyle.line).frame(height: 1).padding(.horizontal, 15)
                    datePickerRow("From", date: Binding(
                        get: { viewModel.filter.startDate ?? Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now },
                        set: { viewModel.filter.startDate = $0 }
                    ))
                    Rectangle().fill(SpendlyticsStyle.line).frame(height: 1).padding(.horizontal, 15)
                    datePickerRow("To", date: Binding(
                        get: { viewModel.filter.endDate ?? .now },
                        set: { viewModel.filter.endDate = $0 }
                    ))
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
        }
    }

    private func datePickerRow(_ title: String, date: Binding<Date>) -> some View {
        HStack {
            Text(title).font(PoppinsFont.regular(11)).foregroundStyle(SpendlyticsStyle.muted)
            Spacer()
            DatePicker(title, selection: date, displayedComponents: .date)
                .labelsHidden().tint(SpendlyticsStyle.accent).font(PoppinsFont.medium(11))
        }
        .padding(.horizontal, 15).padding(.vertical, 10)
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading("Amount", detail: "Set a minimum or maximum")
            HStack(spacing: 11) {
                priceField(label: "MINIMUM", placeholder: "0", text: $minPrice)
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 11)).foregroundStyle(SpendlyticsStyle.muted)
                priceField(label: "MAXIMUM", placeholder: "Any", text: $maxPrice)
            }
        }
    }

    private func priceField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(PoppinsFont.medium(9)).tracking(0.9).foregroundStyle(SpendlyticsStyle.muted)
            HStack(spacing: 5) {
                Text("₹").foregroundStyle(SpendlyticsStyle.muted)
                TextField(placeholder, text: text).keyboardType(.decimalPad).font(PoppinsFont.medium(13))
            }
        }
        .padding(13).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
    }

    private func sectionHeading(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(PoppinsFont.semibold(15)).foregroundStyle(SpendlyticsStyle.ink)
            Text(detail).font(PoppinsFont.regular(10)).foregroundStyle(SpendlyticsStyle.muted)
        }
    }

    private func clearFilters() {
        viewModel.clearFilters()
        minPrice = ""
        maxPrice = ""
        filterByDate = false
    }

    private func applyFilters() {
        viewModel.filter.minPrice = Double(minPrice)
        viewModel.filter.maxPrice = Double(maxPrice)
        if !filterByDate {
            viewModel.filter.startDate = nil
            viewModel.filter.endDate = nil
        }
    }
}
