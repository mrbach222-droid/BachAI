import Foundation

struct ChatLine: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

enum GeminiService {
    static func reply(key: String, history: [ChatLine]) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 45
        let contents: [[String: Any]] = history.suffix(12).map {
            ["role": $0.role, "parts": [["text": $0.content]]]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "systemInstruction": ["parts": [["text": "Bạn là Bách AI, trợ lý tiếng Việt trên iPhone. Trả lời ngắn gọn, không giả vờ đã thực hiện tác vụ."]]],
            "contents": contents
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "BachAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không nhận được phản hồi."])
        }
        guard (200...299).contains(http.statusCode) else {
            throw NSError(domain: "BachAI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Gemini HTTP \(http.statusCode): \(String(decoding: data, as: UTF8.self).prefix(250))"])
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let parts = content?["parts"] as? [[String: Any]]
        guard let answer = parts?.compactMap({ $0["text"] as? String }).first else {
            throw NSError(domain: "BachAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Gemini không trả lời."])
        }
        return answer
    }
}
