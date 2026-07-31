import Foundation

enum OpenFoodFactsError: LocalizedError {
    case notFound
    case network(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .notFound: return "No product found for that barcode. Try Text or Browse instead."
        case .network(let msg): return "Network error: \(msg)"
        case .badResponse: return "Couldn't read product data."
        }
    }
}

enum OpenFoodFactsService {
    static func lookup(barcode: String) async throws -> ParsedFoodResult {
        let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw OpenFoodFactsError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw OpenFoodFactsError.network("status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let status = json["status"] as? Int, status == 1,
            let product = json["product"] as? [String: Any]
        else {
            throw OpenFoodFactsError.notFound
        }

        guard let nutriments = product["nutriments"] as? [String: Any] else {
            throw OpenFoodFactsError.badResponse
        }

        func num(_ key: String) -> Double {
            if let d = nutriments[key] as? Double { return d }
            if let i = nutriments[key] as? Int { return Double(i) }
            if let s = nutriments[key] as? String { return Double(s) ?? 0 }
            return 0
        }

        let name = (product["product_name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Unknown product"
        let sodiumG = num("sodium_100g")

        return ParsedFoodResult(
            name: name,
            calories: num("energy-kcal_100g"),
            protein: num("proteins_100g"),
            carbs: num("carbohydrates_100g"),
            fat: num("fat_100g"),
            fiber: num("fiber_100g"),
            sugar: num("sugars_100g"),
            sodium: sodiumG * 1000
        )
    }
}
