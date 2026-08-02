import SwiftUI

struct BMICard: View {
    let bmi: Double

    private var category: BMICategory { BMICategory.category(for: bmi) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("BMI (kg/m2)")
                    .font(Theme.Font.text(14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(category.label)
                    .font(Theme.Font.text(11, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(category.color, in: Capsule())
            }

            ZStack {
                BMIGaugeView(bmi: bmi)
                    .frame(width: 220, height: 220)

                VStack(spacing: 2) {
                    Text(String(format: "%.1f", bmi))
                        .font(Theme.Font.display(30))
                        .foregroundStyle(Theme.textPrimary)
                    Text("BMI (kg/m2)")
                        .font(Theme.Font.text(10))
                        .foregroundStyle(Theme.textFaint)
                }
                .offset(y: 54)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)

            VStack(spacing: 8) {
                ForEach(BMICategory.allCases, id: \.self) { cat in
                    HStack(spacing: 8) {
                        Circle().fill(cat.color).frame(width: 8, height: 8)
                        Text(cat.label)
                            .font(Theme.Font.text(11, weight: cat == category ? .semibold : .regular))
                            .foregroundStyle(cat == category ? Theme.textPrimary : Theme.textSecondary)
                        Spacer()
                        Text(cat.rangeLabel)
                            .font(Theme.Font.text(11))
                            .foregroundStyle(Theme.textFaint)
                    }
                }
            }
            .padding(.top, 14)
        }
        .padding(16)
        .glassCard(RoundedRectangle(cornerRadius: Theme.Radius.large))
    }
}
