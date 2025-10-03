import Foundation
import os

public enum CafeImageDescriptor: Hashable, Sendable {
    case systemSymbol(String)
    case asset(name: String)
    case remote(url: URL)
}

public protocol CafeDataProviding: Sendable {
    func fetchChains() async throws -> [DokoCafeViewModel.Chain]
}

public enum CafeDataProviderConfiguration {
    case mock
    case remote(URLRequestFactory)

    public typealias URLRequestFactory = @Sendable () throws -> URLRequest
}

public struct RemoteCafeDataProvider: CafeDataProviding {
    public enum RemoteError: LocalizedError {
        case invalidResponse
        case statusCode(Int, message: String?)
        case decoding(Error)
        case request(Error)

        public var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "サーバーからのレスポンスが不正です。"
            case .statusCode(let code, let message):
                if let message, !message.isEmpty {
                    return "サーバーエラー (code: \(code)) - \(message)"
                }
                return "サーバーエラー (code: \(code))"
            case .decoding(let error):
                return "レスポンスの解釈に失敗しました: \(error.localizedDescription)"
            case .request(let error):
                return error.localizedDescription
            }
        }
        
        public var recoverySuggestion: String? {
            switch self {
            case .invalidResponse:
                return "しばらく待ってから再度お試しください。問題が続く場合はサポートにお問い合わせください。"
            case .statusCode(let code, _):
                if code >= 500 {
                    return "サーバーが一時的に利用できません。しばらく待ってから再試行してください。"
                } else if code == 401 || code == 403 {
                    return "認証に失敗しました。アプリを再起動してください。"
                } else if code == 429 {
                    return "リクエストが多すぎます。しばらく待ってから再試行してください。"
                } else {
                    return "問題が続く場合はサポートにお問い合わせください。"
                }
            case .decoding:
                return "データ形式が変更された可能性があります。アプリを最新版に更新してください。"
            case .request(let error as NSError):
                if error.domain == NSURLErrorDomain {
                    switch error.code {
                    case NSURLErrorNotConnectedToInternet:
                        return "インターネット接続を確認してください。"
                    case NSURLErrorTimedOut:
                        return "接続がタイムアウトしました。ネットワーク環境を確認して再試行してください。"
                    default:
                        return "ネットワーク接続を確認して再試行してください。"
                    }
                }
                return "しばらく待ってから再試行してください。"
            }
        }
    }

    private let session: URLSession
    private let decoder: JSONDecoder
    private let requestFactory: CafeDataProviderConfiguration.URLRequestFactory
    private let logger = Logger(subsystem: "com.cafedoko.app", category: "RemoteCafeDataProvider")

    public init(session: URLSession = .shared, requestFactory: @escaping CafeDataProviderConfiguration.URLRequestFactory) {
        self.session = session
        self.requestFactory = requestFactory
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func fetchChains() async throws -> [DokoCafeViewModel.Chain] {
        let request: URLRequest
        do {
            request = try requestFactory()
        } catch {
            logger.error("Failed to build request: \(error.localizedDescription, privacy: .public)")
            throw RemoteError.request(error)
        }

        logger.log("Fetching cafes from \(request.url?.absoluteString ?? "unknown", privacy: .public)")
        let start = Date()

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw RemoteError.invalidResponse
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                let message = decodeErrorMessage(from: data)
                if let message, !message.isEmpty {
                    logger.error("Request failed with status \(httpResponse.statusCode, privacy: .public) message: \(message, privacy: .public)")
                } else {
                    logger.error("Request failed with status \(httpResponse.statusCode, privacy: .public)")
                }
                throw RemoteError.statusCode(httpResponse.statusCode, message: message)
            }

            let decodedChains = try decodeChains(from: data)
            let elapsed = Date().timeIntervalSince(start) * 1000
            logger.log("Fetched \(decodedChains.count) cafes in \(elapsed, format: .fixed(precision: 0)) ms")
            return decodedChains
        } catch let error as RemoteError {
            throw error
        } catch let error as DecodingError {
            logger.error("Decoding error: \(error.localizedDescription, privacy: .public)")
            throw RemoteError.decoding(error)
        } catch {
            logger.error("Request error: \(error.localizedDescription, privacy: .public)")
            throw RemoteError.request(error)
        }
    }

    private func decodeChains(from data: Data) throws -> [DokoCafeViewModel.Chain] {
        if let envelope = try? decoder.decode(ResponseEnvelope.self, from: data) {
            return envelope.chains.map(\.chain)
        }

        let decoded = try decoder.decode([ChainDTO].self, from: data)
        return decoded.map(\.chain)
    }

    private struct ResponseEnvelope: Decodable {
        let chains: [ChainDTO]
        let pagination: Pagination?

        init(from decoder: Decoder) throws {
            if let container = try? decoder.container(keyedBy: CodingKeys.self) {
                if let direct = try container.decodeIfPresent([ChainDTO].self, forKey: .chains) {
                    self.chains = direct
                    self.pagination = try container.decodeIfPresent(Pagination.self, forKey: .pagination)
                    return
                }
                if let dataContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data),
                   let nested = try dataContainer.decodeIfPresent([ChainDTO].self, forKey: .chains) {
                    self.chains = nested
                    self.pagination = try dataContainer.decodeIfPresent(Pagination.self, forKey: .pagination)
                    return
                }
                if let items = try container.decodeIfPresent([ChainDTO].self, forKey: .items) {
                    self.chains = items
                    self.pagination = try container.decodeIfPresent(Pagination.self, forKey: .pagination)
                    return
                }
                if let results = try container.decodeIfPresent([ChainDTO].self, forKey: .results) {
                    self.chains = results
                    self.pagination = try container.decodeIfPresent(Pagination.self, forKey: .pagination)
                    return
                }
            }

            var single = try decoder.singleValueContainer()
            self.chains = try single.decode([ChainDTO].self)
            self.pagination = nil
        }

        private enum CodingKeys: String, CodingKey {
            case chains
            case data
            case items
            case results
            case pagination
        }
    }

    private struct Pagination: Decodable {
        let nextPageToken: String?
        let total: Int?
    }

    private struct ChainDTO: Decodable {
        let rawID: UUID?
        let name: String
        let price: Int
        let sizeLabel: String
        let distance: Int
        let tags: [String]
        let imageURL: URL?
        let updatedAt: Date?
        let address: String?
        let openingHours: String?
        let phoneNumber: String?
        let latitude: Double?
        let longitude: Double?

        var chain: DokoCafeViewModel.Chain {
            .init(
                id: rawID ?? UUID(),
                name: name,
                price: price,
                sizeLabel: sizeLabel,
                distance: distance,
                tags: tags,
                imageURL: imageURL,
                updatedAt: updatedAt,
                address: address,
                openingHours: openingHours,
                phoneNumber: phoneNumber,
                latitude: latitude,
                longitude: longitude
            )
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.rawID = ChainDTO.decodeID(from: container)
            self.name = try container.decode(String.self, forKey: .name)
            self.price = ChainDTO.decodePrice(from: container)
            self.sizeLabel = ChainDTO.decodeSizeLabel(from: container)
            self.distance = ChainDTO.decodeDistance(from: container)
            self.tags = ChainDTO.decodeTags(from: container)
            self.imageURL = ChainDTO.decodeImageURL(from: container)
            self.updatedAt = ChainDTO.decodeUpdatedAt(from: container)
            self.address = ChainDTO.decodeAddress(from: container)
            self.openingHours = ChainDTO.decodeOpeningHours(from: container)
            self.phoneNumber = ChainDTO.decodePhoneNumber(from: container)
            self.latitude = ChainDTO.decodeLatitude(from: container)
            self.longitude = ChainDTO.decodeLongitude(from: container)
        }

        private static func decodeID(from container: KeyedDecodingContainer<CodingKeys>) -> UUID? {
            if let uuid = try? container.decode(UUID.self, forKey: .id) {
                return uuid
            }
            if let uuid = try? container.decode(UUID.self, forKey: .uuid) {
                return uuid
            }
            if let idString = try? container.decode(String.self, forKey: .id), let uuid = UUID(uuidString: idString) {
                return uuid
            }
            if let idString = try? container.decode(String.self, forKey: .uuid), let uuid = UUID(uuidString: idString) {
                return uuid
            }
            return nil
        }

        private static func decodePrice(from container: KeyedDecodingContainer<CodingKeys>) -> Int {
            if let price = try? container.decode(Int.self, forKey: .price) {
                return price
            }
            if let price = try? container.decode(Int.self, forKey: .priceYen) {
                return price
            }
            if let price = try? container.decode(Int.self, forKey: .priceJPY) {
                return price
            }
            if let doublePrice = try? container.decode(Double.self, forKey: .price) {
                return Int(doublePrice.rounded())
            }
            if let stringPrice = try? container.decode(String.self, forKey: .price), let parsed = Int(stringPrice.filter { $0.isNumber }) {
                return parsed
            }
            if let stringPrice = try? container.decode(String.self, forKey: .priceYen), let parsed = Int(stringPrice.filter { $0.isNumber }) {
                return parsed
            }
            return 0
        }

        private static func decodeSizeLabel(from container: KeyedDecodingContainer<CodingKeys>) -> String {
            if let label = try? container.decode(String.self, forKey: .sizeLabel), !label.isEmpty {
                return label
            }
            if let label = try? container.decode(String.self, forKey: .sizeLabelSnake), !label.isEmpty {
                return label
            }
            if let label = try? container.decode(String.self, forKey: .size), !label.isEmpty {
                return label
            }
            return ""
        }

        private static func decodeDistance(from container: KeyedDecodingContainer<CodingKeys>) -> Int {
            if let distance = try? container.decode(Int.self, forKey: .distance) {
                return distance
            }
            if let distance = try? container.decode(Int.self, forKey: .distanceMeters) {
                return distance
            }
            if let doubleDistance = try? container.decode(Double.self, forKey: .distance) {
                return Int(doubleDistance.rounded())
            }
            if let stringDistance = try? container.decode(String.self, forKey: .distance), let parsed = Int(stringDistance.filter { $0.isNumber }) {
                return parsed
            }
            return 0
        }

        private static func decodeTags(from container: KeyedDecodingContainer<CodingKeys>) -> [String] {
            if let tags = try? container.decode([String].self, forKey: .tags) {
                return tags
            }
            if let tags = try? container.decode([String].self, forKey: .categories) {
                return tags
            }
            if let csv = try? container.decode(String.self, forKey: .tagsCSV) {
                return csv.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            return []
        }

        private static func decodeAddress(from container: KeyedDecodingContainer<CodingKeys>) -> String? {
            if let address = try? container.decode(String.self, forKey: .address), !address.isEmpty {
                return address
            }
            return nil
        }
        
        private static func decodeOpeningHours(from container: KeyedDecodingContainer<CodingKeys>) -> String? {
            if let hours = try? container.decode(String.self, forKey: .openingHours), !hours.isEmpty {
                return hours
            }
            if let hours = try? container.decode(String.self, forKey: .businessHours), !hours.isEmpty {
                return hours
            }
            return nil
        }
        
        private static func decodePhoneNumber(from container: KeyedDecodingContainer<CodingKeys>) -> String? {
            if let phone = try? container.decode(String.self, forKey: .phoneNumber), !phone.isEmpty {
                return phone
            }
            if let phone = try? container.decode(String.self, forKey: .phone), !phone.isEmpty {
                return phone
            }
            return nil
        }

        private static func decodeLatitude(from container: KeyedDecodingContainer<CodingKeys>) -> Double? {
            if let lat = try? container.decode(Double.self, forKey: .latitude) {
                return lat
            }
            if let lat = try? container.decode(Double.self, forKey: .lat) {
                return lat
            }
            return nil
        }

        private static func decodeLongitude(from container: KeyedDecodingContainer<CodingKeys>) -> Double? {
            if let lon = try? container.decode(Double.self, forKey: .longitude) {
                return lon
            }
            if let lon = try? container.decode(Double.self, forKey: .lon) {
                return lon
            }
            if let lon = try? container.decode(Double.self, forKey: .lng) {
                return lon
            }
            return nil
        }

        private static func decodeImageURL(from container: KeyedDecodingContainer<CodingKeys>) -> URL? {
            if let url = try? container.decode(URL.self, forKey: .imageURL) {
                return url
            }
            if let url = try? container.decode(URL.self, forKey: .thumbnailURL) {
                return url
            }
            if let urlString = try? container.decode(String.self, forKey: .imageURL), let url = URL(string: urlString) {
                return url
            }
            if let urlString = try? container.decode(String.self, forKey: .thumbnailURL), let url = URL(string: urlString) {
                return url
            }
            return nil
        }

        private static func decodeUpdatedAt(from container: KeyedDecodingContainer<CodingKeys>) -> Date? {
            if let isoString = try? container.decode(String.self, forKey: .updatedAt) {
                return ISO8601DateFormatter().date(from: isoString)
            }
            if let timestamp = try? container.decode(Double.self, forKey: .updatedAt) {
                return Date(timeIntervalSince1970: timestamp)
            }
            return nil
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case uuid
            case name
            case price
            case priceYen = "price_yen"
            case priceJPY = "price_jpy"
            case sizeLabel
            case sizeLabelSnake = "size_label"
            case size
            case distance
            case distanceMeters = "distance_meters"
            case tags
            case categories
            case tagsCSV = "tags_csv"
            case imageURL = "image_url"
            case thumbnailURL = "thumbnail_url"
            case updatedAt = "updated_at"
            case address
            case openingHours = "opening_hours"
            case businessHours = "business_hours"
            case phoneNumber = "phone_number"
            case phone
            case latitude
            case longitude
            case lat
            case lon
            case lng
        }
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        guard let envelope = try? decoder.decode(ErrorEnvelope.self, from: data) else { return nil }
        return envelope.messageValue
    }

    private struct ErrorEnvelope: Decodable {
        let error: String?
        let message: String?

        var messageValue: String? {
            if let message, !message.isEmpty { return message }
            if let error, !error.isEmpty { return error }
            return nil
        }
    }
}

public protocol CafeImageProviding: Sendable {
    func imageDescriptor(for chain: DokoCafeViewModel.Chain) -> CafeImageDescriptor
}

/// Empty data provider for fallback scenarios
public struct EmptyCafeDataProvider: CafeDataProviding {
    public init() {}
    
    public func fetchChains() async throws -> [DokoCafeViewModel.Chain] {
        []
    }
}

public struct LocalJSONCafeDataProvider: CafeDataProviding {
    private let url: URL
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.url = fileURL
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func fetchChains() async throws -> [DokoCafeViewModel.Chain] {
        let data = try Data(contentsOf: url)
        if let envelope = try? decoder.decode(ResponseEnvelope.self, from: data), let chains = envelope.chains {
            return chains.map(\.chain)
        }
        let decoded = try decoder.decode([ChainDTO].self, from: data)
        return decoded.map(\.chain)
    }

    private struct ResponseEnvelope: Decodable {
        let chains: [ChainDTO]?
    }

    private struct ChainDTO: Decodable {
        let name: String
        let price: Int
        let sizeLabel: String
        let distance: Int
        let tags: [String]

        var chain: DokoCafeViewModel.Chain {
            .init(name: name, price: price, sizeLabel: sizeLabel, distance: distance, tags: tags)
        }
    }
}

public struct SymbolCafeImageProvider: CafeImageProviding {
    public init() {}

    public func imageDescriptor(for chain: DokoCafeViewModel.Chain) -> CafeImageDescriptor {
        if let url = chain.imageURL {
            return .remote(url: url)
        }
        return .systemSymbol(symbolName(for: chain))
    }

    private func symbolName(for chain: DokoCafeViewModel.Chain) -> String {
        let lowered = chain.name.lowercased()
        if lowered.contains("スターバックス") || lowered.contains("starbucks") {
            return "cup.and.saucer.fill"
        }
        if lowered.contains("ドトール") {
            return "takeoutbag.and.cup.and.straw.fill"
        }
        if lowered.contains("タリーズ") {
            return "leaf"
        }
        if lowered.contains("セブン") {
            return "storefront"
        }
        return "cup.and.saucer"
    }
}
