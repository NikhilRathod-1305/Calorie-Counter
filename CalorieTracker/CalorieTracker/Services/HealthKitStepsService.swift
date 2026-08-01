import Foundation
import HealthKit

enum HealthKitStepsService {
    static let isAvailable = HKHealthStore.isHealthDataAvailable()

    private static let store = HKHealthStore()
    private static let stepType = HKQuantityType(.stepCount)

    static func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
            return true
        } catch {
            return false
        }
    }

    static func todaySteps() async throws -> Int {
        try await steps(on: Date())
    }

    static func steps(on day: Date) async throws -> Int {
        guard isAvailable else { return 0 }
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = min(cal.date(byAdding: .day, value: 1, to: start) ?? Date(), Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(sum))
            }
            store.execute(query)
        }
    }

    /// Daily step totals from `start` through today, keyed by the start-of-day `Date`.
    static func dailySteps(from start: Date) async throws -> [Date: Int] {
        guard isAvailable else { return [:] }
        let cal = Calendar.current
        let anchor = cal.startOfDay(for: start)
        let interval = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: anchor, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                var totals: [Date: Int] = [:]
                results?.enumerateStatistics(from: anchor, to: Date()) { statistics, _ in
                    let sum = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    totals[cal.startOfDay(for: statistics.startDate)] = Int(sum)
                }
                continuation.resume(returning: totals)
            }
            store.execute(query)
        }
    }
}
