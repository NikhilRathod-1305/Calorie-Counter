import Foundation
import UIKit

struct ParsedFoodResult {
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
}

enum GeminiFoodServiceError: LocalizedError {
    case missingAPIKey
    case invalidImage
    case network(String)
    case badResponse
    case noFunctionCall

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Add your Gemini API key in Profile to use AI food recognition."
        case .invalidImage: return "Couldn't read that photo."
        case .network(let msg): return "Network error: \(msg)"
        case .badResponse: return "Gemini couldn't parse a response. Try again or use Browse."
        case .noFunctionCall: return "Couldn't identify that food. Try again or use Browse."
        }
    }
}

enum GeminiFoodService {
    private static let modelFallbacks = ["gemini-3.6-flash", "gemini-flash-latest", "gemini-2.5-flash"]
    private static let functionName = "log_food"

    private static func endpoint(model: String) -> URL {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
    }

    private static let logFoodFunction: [String: Any] = [
        "name": functionName,
        "description": "Report the identified food item and its nutritional values for a single standard serving as described.",
        "parameters": [
            "type": "object",
            "properties": [
                "name": ["type": "string", "description": "Short, natural name of the food or meal."],
                "calories": ["type": "number"],
                "protein_g": ["type": "number"],
                "carbs_g": ["type": "number"],
                "fat_g": ["type": "number"],
                "fiber_g": ["type": "number"],
                "sugar_g": ["type": "number"],
                "sodium_mg": ["type": "number"]
            ],
            "required": ["name", "calories", "protein_g", "carbs_g", "fat_g", "fiber_g", "sugar_g", "sodium_mg"]
        ]
    ]

    static func parseText(_ description: String) async throws -> ParsedFoodResult {
        guard let apiKey = KeychainStore.loadAPIKey(), !apiKey.isEmpty else {
            throw GeminiFoodServiceError.missingAPIKey
        }
        let prompt = "Estimate the nutrition for this food/meal description, using reasonable standard portions when not specified: \"\(description)\""
        let parts: [[String: Any]] = [["text": prompt]]
        return try await send(apiKey: apiKey, parts: parts)
    }

    static func parseImage(_ image: UIImage) async throws -> ParsedFoodResult {
        guard let apiKey = KeychainStore.loadAPIKey(), !apiKey.isEmpty else {
            throw GeminiFoodServiceError.missingAPIKey
        }
        guard let downscaled = image.downscaledForUpload(maxDimension: 1024),
              let jpegData = downscaled.jpegData(compressionQuality: 0.7) else {
            throw GeminiFoodServiceError.invalidImage
        }
        let base64 = jpegData.base64EncodedString()
        let parts: [[String: Any]] = [
            [
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64
                ]
            ],
            ["text": "Identify the food or meal in this photo and estimate its total nutrition based on typical portion size shown."]
        ]
        return try await send(apiKey: apiKey, parts: parts)
    }

    private static func send(apiKey: String, parts: [[String: Any]]) async throws -> ParsedFoodResult {
        var lastError: Error = GeminiFoodServiceError.badResponse
        for model in modelFallbacks {
            do {
                return try await send(apiKey: apiKey, parts: parts, model: model)
            } catch let error as GeminiFoodServiceError {
                lastError = error
                if case .network(let msg) = error, msg.hasPrefix("status 404") {
                    continue
                }
                throw error
            }
        }
        throw lastError
    }

    private static func send(apiKey: String, parts: [[String: Any]], model: String) async throws -> ParsedFoodResult {
        var request = URLRequest(url: endpoint(model: model))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let body: [String: Any] = [
            "contents": [
                ["role": "user", "parts": parts]
            ],
            "systemInstruction": [
                "parts": [["text": "You are a nutrition estimation assistant. Always call the log_food function exactly once with your best estimate. Never ask clarifying questions."]]
            ],
            "tools": [
                ["functionDeclarations": [logFoodFunction]]
            ],
            "toolConfig": [
                "functionCallingConfig": [
                    "mode": "ANY",
                    "allowedFunctionNames": [functionName]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GeminiFoodServiceError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw GeminiFoodServiceError.network("status \((response as? HTTPURLResponse)?.statusCode ?? -1): \(bodyText.prefix(200))")
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let firstCandidate = candidates.first,
            let content = firstCandidate["content"] as? [String: Any],
            let responseParts = content["parts"] as? [[String: Any]]
        else {
            throw GeminiFoodServiceError.badResponse
        }

        for part in responseParts {
            guard let functionCall = part["functionCall"] as? [String: Any],
                  let args = functionCall["args"] as? [String: Any] else { continue }

            func num(_ key: String) -> Double {
                (args[key] as? Double) ?? Double(args[key] as? Int ?? 0)
            }

            let name = (args["name"] as? String) ?? "Meal"
            return ParsedFoodResult(
                name: name,
                calories: num("calories"),
                protein: num("protein_g"),
                carbs: num("carbs_g"),
                fat: num("fat_g"),
                fiber: num("fiber_g"),
                sugar: num("sugar_g"),
                sodium: num("sodium_mg")
            )
        }

        throw GeminiFoodServiceError.noFunctionCall
    }
}

private extension UIImage {
    func downscaledForUpload(maxDimension: CGFloat) -> UIImage? {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
