import SwiftUI

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color

    var body: some View {
        SoftCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    Circle().fill(color).frame(width: 7, height: 7)
                    Text(title.uppercased()).font(PoppinsFont.medium(9)).tracking(1).foregroundStyle(SpendlyticsStyle.muted)
                }
                Text("₹\(amount, specifier: "%.2f")")
                    .font(PoppinsFont.semibold(18)).foregroundStyle(SpendlyticsStyle.ink)
                    .minimumScaleFactor(0.75).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
