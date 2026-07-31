import Foundation

enum DataExportService {
    private static func csvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    static func exportCSV(
        meals: [MealEntry],
        exercise: [ExerciseEntry],
        weight: [WeightLogEntry],
        water: [WaterLogEntry]
    ) -> URL? {
        var lines: [String] = []

        lines.append("Section,Date,Name,Meal/Type,Calories,Protein(g),Carbs(g),Fat(g),Fiber(g),Sugar(g),Sodium(mg),Amount")

        for entry in meals.sorted(by: { $0.timestamp < $1.timestamp }) {
            let n = entry.nutrition
            lines.append([
                "Food", dateString(entry.timestamp), csvField(entry.displayName), entry.mealType.rawValue,
                String(format: "%.0f", n.calories), String(format: "%.1f", n.protein), String(format: "%.1f", n.carbs),
                String(format: "%.1f", n.fat), String(format: "%.1f", n.fiber), String(format: "%.1f", n.sugar),
                String(format: "%.0f", n.sodium), ""
            ].joined(separator: ","))
        }

        for entry in exercise.sorted(by: { $0.timestamp < $1.timestamp }) {
            lines.append([
                "Exercise", dateString(entry.timestamp), csvField(entry.name), "",
                String(format: "-%.0f", entry.caloriesBurned), "", "", "", "", "", "",
                entry.durationMinutes.map { "\(Int($0)) min" } ?? ""
            ].joined(separator: ","))
        }

        for entry in weight.sorted(by: { $0.date < $1.date }) {
            lines.append([
                "Weight", dateString(entry.date), "", "", "", "", "", "", "", "", "",
                String(format: "%.1f kg", entry.weightKg)
            ].joined(separator: ","))
        }

        for entry in water.sorted(by: { $0.date < $1.date }) {
            lines.append([
                "Water", dateString(entry.date), "", "", "", "", "", "", "", "", "",
                "\(entry.milliliters) ml"
            ].joined(separator: ","))
        }

        let csv = lines.joined(separator: "\n")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "CountOnMe-Export-\(formatter.string(from: Date())).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
