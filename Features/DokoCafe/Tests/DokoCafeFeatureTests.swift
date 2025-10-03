import XCTest
@testable import DokoCafeFeature

@MainActor
final class DokoCafeFeatureTests: XCTestCase {
    func testChainsSortedByPriceAscending() async {
        let chains: [DokoCafeViewModel.Chain] = [
            .init(name: "A", price: 400, sizeLabel: "M", distance: 300),
            .init(name: "B", price: 320, sizeLabel: "M", distance: 180),
            .init(name: "C", price: 500, sizeLabel: "L", distance: 220)
        ]
        let stubProvider = StubDataProvider(chains: chains)
        let viewModel = DokoCafeViewModel(dataProvider: stubProvider, imageProvider: SymbolCafeImageProvider())

        await viewModel.reload()

        let sortedNames = viewModel.chains(sortedBy: .byPriceAscending).map(\.name)
        XCTAssertEqual(sortedNames, ["B", "A", "C"])
    }

    func testChainsSortedByDistanceAscending() async {
        let chains: [DokoCafeViewModel.Chain] = [
            .init(name: "A", price: 400, sizeLabel: "M", distance: 300),
            .init(name: "B", price: 320, sizeLabel: "M", distance: 180),
            .init(name: "C", price: 500, sizeLabel: "L", distance: 220)
        ]
        let stubProvider = StubDataProvider(chains: chains)
        let viewModel = DokoCafeViewModel(dataProvider: stubProvider, imageProvider: SymbolCafeImageProvider())

        await viewModel.reload()

        let sortedNames = viewModel.chains(sortedBy: .byDistanceAscending).map(\.name)
        XCTAssertEqual(sortedNames, ["B", "C", "A"])
    }
}

private struct StubDataProvider: CafeDataProviding {
    let chains: [DokoCafeViewModel.Chain]

    func fetchChains() async throws -> [DokoCafeViewModel.Chain] {
        chains
    }
}
