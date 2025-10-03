import Foundation
import Observation
import os

@Observable
public final class DokoCafeViewModel {
    public struct Chain: Identifiable, Hashable, Sendable {
        public let id: UUID
        public var name: String
        public var price: Int
        public var sizeLabel: String
        public var distance: Int
        public var tags: [String]
        public var imageURL: URL?
        public var updatedAt: Date?
        public var address: String?
        public var openingHours: String?
        public var phoneNumber: String?
        public var latitude: Double?
        public var longitude: Double?

        public init(
            id: UUID = .init(),
            name: String,
            price: Int,
            sizeLabel: String,
            distance: Int,
            tags: [String] = [],
            imageURL: URL? = nil,
            updatedAt: Date? = nil,
            address: String? = nil,
            openingHours: String? = nil,
            phoneNumber: String? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil
        ) {
            self.id = id
            self.name = name
            self.price = price
            self.sizeLabel = sizeLabel
            self.distance = distance
            self.tags = tags
            self.imageURL = imageURL
            self.updatedAt = updatedAt
            self.address = address
            self.openingHours = openingHours
            self.phoneNumber = phoneNumber
            self.latitude = latitude
            self.longitude = longitude
        }
    }

    @ObservationIgnored private let dataProvider: any CafeDataProviding
    @ObservationIgnored private let imageProvider: any CafeImageProviding
    @ObservationIgnored private let logger = Logger(subsystem: "com.cafedoko.app", category: "DokoCafeViewModel")

    public private(set) var chains: [Chain]
    public private(set) var isLoading = false
    public private(set) var lastErrorMessage: String?
    private var imageCache: [UUID: CafeImageDescriptor] = [:]

    public init(
        dataProvider: any CafeDataProviding,
        imageProvider: any CafeImageProviding = SymbolCafeImageProvider(),
        initialChains: [Chain] = []
    ) {
        self.dataProvider = dataProvider
        self.imageProvider = imageProvider
        self.chains = initialChains
    }

    public func chains(sortedBy sort: SortDescriptor) -> [Chain] {
        guard let keyPath = sort.keyPath else {
            return chains
        }
        return chains.sorted { lhs, rhs in
            if sort.order == .ascending {
                return lhs[keyPath: keyPath] < rhs[keyPath: keyPath]
            } else {
                return lhs[keyPath: keyPath] > rhs[keyPath: keyPath]
            }
        }
    }

    @MainActor
    public func reload() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await dataProvider.fetchChains()
            self.chains = fetched
            self.imageCache = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, imageProvider.imageDescriptor(for: $0)) })
            self.lastErrorMessage = nil
            self.logger.log("Fetched \(self.chains.count) cafe entries")
        } catch {
            self.lastErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            self.logger.error("Failed to fetch cafes: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func imageDescriptor(for chain: Chain) -> CafeImageDescriptor {
        if let descriptor = imageCache[chain.id] {
            return descriptor
        }
        let descriptor = imageProvider.imageDescriptor(for: chain)
        imageCache[chain.id] = descriptor
        return descriptor
    }

    public func clearError() {
        self.lastErrorMessage = nil
    }
}

public extension DokoCafeViewModel {
    struct SortDescriptor {
        public enum Order { case ascending, descending }

        public let keyPath: KeyPath<Chain, Int>?
        public let order: Order

        public init(keyPath: KeyPath<Chain, Int>?, order: Order) {
            self.keyPath = keyPath
            self.order = order
        }

        public static let byPriceAscending = SortDescriptor(keyPath: \Chain.price, order: .ascending)
        public static let byDistanceAscending = SortDescriptor(keyPath: \Chain.distance, order: .ascending)
        public static let byPriceDescending = SortDescriptor(keyPath: \Chain.price, order: .descending)
    }
}
