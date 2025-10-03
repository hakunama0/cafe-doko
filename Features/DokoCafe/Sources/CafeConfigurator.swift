import Foundation

public enum CafeConfigError: Error {
    case missingResource
    case invalidFormat
}

public struct CafeConfig: Decodable {
    public enum Provider: String, Decodable {
        case mock
        case remote
        case google_places
    }

    public let provider: Provider
    public let remoteURL: URL?
    public let headers: [String: String]
    public let googlePlacesApiKey: String?

    public init(provider: Provider, remoteURL: URL? = nil, headers: [String: String] = [:], googlePlacesApiKey: String? = nil) {
        self.provider = provider
        self.remoteURL = remoteURL
        self.headers = headers
        self.googlePlacesApiKey = googlePlacesApiKey
    }
}

public struct CafeConfigLoader {
    public init() {}

    public func loadConfig(
        from bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> CafeConfig {
        guard let url = bundle.url(forResource: "cafe-doko-config", withExtension: "json") else {
            return CafeConfig(provider: .mock)
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(ConfigDTO.self, from: data)
        return decoded.config(environment: environment)
    }

    private struct ConfigDTO: Decodable {
        let dataProvider: String
        let remote: Remote?
        let googlePlaces: GooglePlaces?

        struct Remote: Decodable {
            let url: URL
            let headers: [String: String]?
        }
        
        struct GooglePlaces: Decodable {
            let apiKey: String
            
            enum CodingKeys: String, CodingKey {
                case apiKey = "api_key"
            }
        }

        func config(environment: [String: String]) -> CafeConfig {
            switch dataProvider.lowercased() {
            case "remote":
                let resolvedHeaders = resolveHeaders(remote?.headers ?? [:], environment: environment)
                return CafeConfig(provider: .remote, remoteURL: remote?.url, headers: resolvedHeaders)
            case "google_places":
                let apiKey = googlePlaces?.apiKey ?? ""
                let resolvedApiKey = resolveHeaderValue(apiKey, environment: environment) ?? ""
                return CafeConfig(provider: .google_places, googlePlacesApiKey: resolvedApiKey)
            default:
                return CafeConfig(provider: .mock)
            }
        }

        private func resolveHeaders(_ headers: [String: String], environment: [String: String]) -> [String: String] {
            headers.reduce(into: [:]) { result, pair in
                let (key, value) = pair
                guard let resolved = resolveHeaderValue(value, environment: environment), !resolved.isEmpty else {
                    return
                }
                result[key] = resolved
            }
        }

        private func resolveHeaderValue(_ value: String, environment: [String: String]) -> String? {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if let envKey = extractEnvKey(from: trimmed) {
                return environment[envKey]
            }
            return trimmed
        }

        private func extractEnvKey(from value: String) -> String? {
            if value.hasPrefix("$env:") {
                return String(value.dropFirst(5))
            }
            if value.hasPrefix("$ENV:") {
                return String(value.dropFirst(5))
            }
            if value.hasPrefix("$env{") && value.hasSuffix("}") {
                return String(value.dropFirst(5).dropLast())
            }
            if value.hasPrefix("$ENV{") && value.hasSuffix("}") {
                return String(value.dropFirst(5).dropLast())
            }
            if value.hasPrefix("${") && value.hasSuffix("}") {
                return String(value.dropFirst(2).dropLast())
            }
            return nil
        }
    }
}
