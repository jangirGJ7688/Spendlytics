import SwiftUI

struct SummaryView: View {
    let expenses: [Expense]
    @StateObject private var viewModel = SummaryViewModel()

    var body: some View {
        ZStack {
            SpendlyticsStyle.canvas.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    totalSection
                    if !viewModel.insights.isEmpty { insightsSection }
                    pieChartSection
                    lastThreeMonthsSection
                    lastFourWeeksSection
                }
                .padding(20).padding(.bottom, 28)
            }
        }
        .navigationTitle("Your insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Your insights").font(PoppinsFont.semibold(15)).foregroundStyle(SpendlyticsStyle.ink)
            }
        }
        .task { await viewModel.fetchAIInsights(expenses: expenses) }
    }

    private var totalSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("SPENDING OVERVIEW", systemImage: "sparkles")
                    .font(PoppinsFont.medium(10)).tracking(1.1).foregroundStyle(.white.opacity(0.78))
                Spacer()
                Image(systemName: "chart.pie.fill").font(.system(size: 18)).foregroundStyle(.white.opacity(0.76))
            }
            Text("₹\(viewModel.totalExpense(from: expenses), specifier: "%.2f")")
                .font(PoppinsFont.bold(34)).foregroundStyle(.white).minimumScaleFactor(0.72).lineLimit(1)
            HStack(spacing: 7) {
                Image(systemName: "creditcard.fill").font(.system(size: 11))
                Text("Across \(expenses.count) recorded expenses").font(PoppinsFont.regular(11))
            }
            .foregroundStyle(.white.opacity(0.78))
        }
        .padding(21)
        .background(LinearGradient(colors: [SpendlyticsStyle.ink, Color(red: 0.19, green: 0.27, blue: 0.44)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }

    private var pieChartSection: some View {
        let data = viewModel.categoryExpenses(from: expenses)
        return chartCard(title: "Spending by category", subtitle: "Where your money goes") {
            if data.isEmpty { chartEmptyState } else {
                PieChartView(data: data, value: { $0.amount }, label: { $0.category })
                    .frame(height: 265)
            }
        }
    }

    private var lastThreeMonthsSection: some View {
        chartCard(title: "Last 3 months", subtitle: "A monthly snapshot") {
            let data = viewModel.lastThreeMonthsExpenses(from: expenses)
            if data.isEmpty { chartEmptyState } else {
                PieChartView(data: data, value: { $0.amount }, label: { $0.month }).frame(height: 235)
            }
        }
    }

    private var lastFourWeeksSection: some View {
        chartCard(title: "Last 4 weeks", subtitle: "Your weekly rhythm") {
            let data = viewModel.lastFourWeeksExpenses(from: expenses)
            if data.isEmpty { chartEmptyState } else {
                PieChartView(data: data, value: { $0.amount }, label: { $0.week }).frame(height: 235)
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            sectionHeading(title: "Smart insights", subtitle: "Patterns from your spending")
            ForEach(viewModel.insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 11) {
                    Image(systemName: "sparkles").font(.system(size: 14)).foregroundStyle(SpendlyticsStyle.accent)
                        .frame(width: 30, height: 30).background(SpendlyticsStyle.accent.opacity(0.1), in: Circle())
                    Text(insight).font(PoppinsFont.regular(12)).foregroundStyle(SpendlyticsStyle.ink).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(SpendlyticsStyle.line, lineWidth: 1))
            }
        }
    }

    private var chartEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie").font(.system(size: 25)).foregroundStyle(SpendlyticsStyle.accent.opacity(0.7))
            Text("Not enough data yet").font(PoppinsFont.medium(12)).foregroundStyle(SpendlyticsStyle.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }

    private func sectionHeading(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(PoppinsFont.semibold(17)).foregroundStyle(SpendlyticsStyle.ink)
            Text(subtitle).font(PoppinsFont.regular(10)).foregroundStyle(SpendlyticsStyle.muted)
        }
    }

    private func chartCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(title: title, subtitle: subtitle)
            SoftCard(padding: 14) { content() }
        }
    }
}
