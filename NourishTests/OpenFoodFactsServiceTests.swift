import XCTest
import Foundation
@testable import Nourish

// MARK: - Mock URL Protocol for Network Interception

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Mock OpenFoodFacts Service

final class MockOpenFoodFactsService: OpenFoodFactsServiceProtocol, @unchecked Sendable {
    var stubbedResult: Result<FoodItem?, Error> = .success(nil)
    var fetchProductCallCount = 0
    var lastScannedBarcode: String?

    func fetchProduct(barcode: String) async throws -> FoodItem? {
        fetchProductCallCount += 1
        lastScannedBarcode = barcode
        switch stubbedResult {
        case .success(let item):
            return item
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Mock JSON Fixtures

enum MockJSONFixtures {
    static let nutellaStandardJSON = """
    {
      "status": 1,
      "status_verbose": "product found",
      "code": "3017620422003",
      "product": {
        "product_name": "Nutella Hazelnut Spread",
        "brands": "Ferrero",
        "serving_size": "15g",
        "nutriments": {
          "energy-kcal_100g": 539.0,
          "energy-kcal_serving": 80.85,
          "proteins_100g": 6.3,
          "proteins_serving": 0.95,
          "carbohydrates_100g": 57.5,
          "carbohydrates_serving": 8.63,
          "fat_100g": 30.9,
          "fat_serving": 4.64
        }
      }
    }
    """

    static let oats100gOnlyJSON = """
    {
      "status": 1,
      "status_verbose": "product found",
      "code": "0043000017127",
      "product": {
        "product_name": "Rolled Oats",
        "brands": "Quaker",
        "nutriments": {
          "energy-kcal_100g": 389.0,
          "proteins_100g": 16.9,
          "carbohydrates_100g": 66.3,
          "fat_100g": 6.9
        }
      }
    }
    """

    static let energyInJoulesOnlyJSON = """
    {
      "status": 1,
      "status_verbose": "product found",
      "code": "5000111001111",
      "product": {
        "product_name": "Sparkling Water",
        "brands": "Perrier",
        "nutriments": {
          "energy_100g": 0.0,
          "proteins_100g": 0.0,
          "carbohydrates_100g": 0.0,
          "fat_100g": 0.0
        }
      }
    }
    """

    static let missingNutrimentsJSON = """
    {
      "status": 1,
      "status_verbose": "product found",
      "code": "1234567890123",
      "product": {
        "product_name": "Mystery Snack",
        "brands": "Generic Brand"
      }
    }
    """

    static let productNotFoundJSON = """
    {
      "status": 0,
      "status_verbose": "product not found",
      "code": "0000000000000"
    }
    """

    static let malformedJSON = """
    {
      "status": 1,
      "product": {
        "nutriments": "this-should-be-an-object-not-a-string"
      }
    }
    """
}

// MARK: - OpenFoodFactsService Unit Tests

final class OpenFoodFactsServiceTests: XCTestCase {

    private var service: OpenFoodFactsService!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        service = OpenFoodFactsService(session: session)
    }

    override func tearDown() {
        service = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Parsing Tests

    func testFetchProductSuccessWithServingNutriments() async throws {
        let json = MockJSONFixtures.nutellaStandardJSON
        let data = Data(json.utf8)

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("3017620422003") ?? false)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let item = try await service.fetchProduct(barcode: "3017620422003")

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "Nutella Hazelnut Spread")
        XCTAssertEqual(item?.brand, "Ferrero")
        XCTAssertEqual(item?.barcode, "3017620422003")
        // If serving sizes are available, serving values or 100g values are parsed cleanly
        XCTAssertEqual(item?.calories, 80.85)
        XCTAssertEqual(item?.proteinGrams, 0.95)
        XCTAssertEqual(item?.carbsGrams, 8.63)
        XCTAssertEqual(item?.fatGrams, 4.64)
    }

    func testFetchProductSuccessFallbackTo100gNutriments() async throws {
        let json = MockJSONFixtures.oats100gOnlyJSON
        let data = Data(json.utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let item = try await service.fetchProduct(barcode: "0043000017127")

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "Rolled Oats")
        XCTAssertEqual(item?.brand, "Quaker")
        XCTAssertEqual(item?.calories, 389.0)
        XCTAssertEqual(item?.proteinGrams, 16.9)
        XCTAssertEqual(item?.carbsGrams, 66.3)
        XCTAssertEqual(item?.fatGrams, 6.9)
    }

    func testFetchProductWithMissingNutrimentsDefaultsToZero() async throws {
        let json = MockJSONFixtures.missingNutrimentsJSON
        let data = Data(json.utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let item = try await service.fetchProduct(barcode: "1234567890123")

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "Mystery Snack")
        XCTAssertEqual(item?.brand, "Generic Brand")
        XCTAssertEqual(item?.calories, 0.0)
        XCTAssertEqual(item?.proteinGrams, 0.0)
        XCTAssertEqual(item?.carbsGrams, 0.0)
        XCTAssertEqual(item?.fatGrams, 0.0)
    }

    func testFetchProductEnergyJoulesConversion() async throws {
        let json = MockJSONFixtures.energyInJoulesOnlyJSON
        let data = Data(json.utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        let item = try await service.fetchProduct(barcode: "5000111001111")

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "Sparkling Water")
        XCTAssertEqual(item?.calories, 0.0)
    }

    // MARK: - Error Handling Tests

    func testFetchProductNotFoundStatus0Throws() async {
        let json = MockJSONFixtures.productNotFoundJSON
        let data = Data(json.utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        do {
            _ = try await service.fetchProduct(barcode: "0000000000000")
            XCTFail("Expected productNotFound error to be thrown")
        } catch let error as OpenFoodFactsError {
            XCTAssertEqual(error, .productNotFound)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchProductEmptyOrInvalidBarcodeThrows() async {
        do {
            _ = try await service.fetchProduct(barcode: "")
            XCTFail("Expected invalidBarcode error")
        } catch let error as OpenFoodFactsError {
            XCTAssertEqual(error, .invalidBarcode)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        do {
            _ = try await service.fetchProduct(barcode: "   ")
            XCTFail("Expected invalidBarcode error")
        } catch let error as OpenFoodFactsError {
            XCTAssertEqual(error, .invalidBarcode)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchProductServerErrorThrows() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        do {
            _ = try await service.fetchProduct(barcode: "3017620422003")
            XCTFail("Expected serverError")
        } catch let error as OpenFoodFactsError {
            XCTAssertEqual(error, .serverError(statusCode: 500))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchProductMalformedJSONThrows() async {
        let json = MockJSONFixtures.malformedJSON
        let data = Data(json.utf8)

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        do {
            _ = try await service.fetchProduct(barcode: "3017620422003")
            XCTFail("Expected decodingError")
        } catch let error as OpenFoodFactsError {
            if case .decodingError = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected decodingError but got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchProductNetworkFailureThrows() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            _ = try await service.fetchProduct(barcode: "3017620422003")
            XCTFail("Expected networkError")
        } catch let error as OpenFoodFactsError {
            if case .networkError = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected networkError but got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - BarcodeScannerViewModel Tests

    @MainActor
    func testViewModelInitialState() {
        let mock = MockOpenFoodFactsService()
        let vm = BarcodeScannerViewModel(service: mock)

        XCTAssertEqual(vm.state, .idle)
        XCTAssertNil(vm.scannedFoodItem)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isScanning)
    }

    @MainActor
    func testViewModelStartAndPauseScanning() {
        let mock = MockOpenFoodFactsService()
        let vm = BarcodeScannerViewModel(service: mock)

        vm.startScanning()
        XCTAssertEqual(vm.state, .scanning)
        XCTAssertTrue(vm.isScanning)

        vm.pauseScanning()
        XCTAssertEqual(vm.state, .idle)
        XCTAssertFalse(vm.isScanning)
    }

    @MainActor
    func testViewModelSuccessfulBarcodeScan() async {
        let mock = MockOpenFoodFactsService()
        let expectedItem = FoodItem(
            name: "Protein Shake",
            barcode: "1122334455",
            brand: "MuscleCo",
            calories: 180,
            proteinGrams: 30,
            carbsGrams: 5,
            fatGrams: 3
        )
        mock.stubbedResult = .success(expectedItem)

        let vm = BarcodeScannerViewModel(service: mock)
        vm.startScanning()

        await vm.processScannedBarcode("1122334455")

        XCTAssertEqual(mock.fetchProductCallCount, 1)
        XCTAssertEqual(mock.lastScannedBarcode, "1122334455")
        XCTAssertEqual(vm.state, .success(expectedItem))
        XCTAssertEqual(vm.scannedFoodItem?.name, "Protein Shake")
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    @MainActor
    func testViewModelProductNotFound() async {
        let mock = MockOpenFoodFactsService()
        mock.stubbedResult = .failure(OpenFoodFactsError.productNotFound)

        let vm = BarcodeScannerViewModel(service: mock)
        vm.startScanning()

        await vm.processScannedBarcode("999999999")

        XCTAssertEqual(mock.fetchProductCallCount, 1)
        if case .error(let msg) = vm.state {
            XCTAssertTrue(msg.contains("No product found") || msg.contains("not found"))
        } else {
            XCTFail("State should be .error")
        }
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.scannedFoodItem)
    }

    @MainActor
    func testViewModelNetworkError() async {
        let mock = MockOpenFoodFactsService()
        mock.stubbedResult = .failure(OpenFoodFactsError.networkError("Offline"))

        let vm = BarcodeScannerViewModel(service: mock)
        vm.startScanning()

        await vm.processScannedBarcode("123456")

        XCTAssertEqual(mock.fetchProductCallCount, 1)
        if case .error(let msg) = vm.state {
            XCTAssertTrue(msg.contains("Network connection error") || msg.contains("Offline"))
        } else {
            XCTFail("State should be .error")
        }
        XCTAssertNotNil(vm.errorMessage)
    }

    @MainActor
    func testViewModelInvalidBarcode() async {
        let mock = MockOpenFoodFactsService()
        let vm = BarcodeScannerViewModel(service: mock)
        vm.startScanning()

        await vm.processScannedBarcode("   ")

        XCTAssertEqual(mock.fetchProductCallCount, 0)
        if case .error = vm.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("State should be .error for empty barcode")
        }
    }

    @MainActor
    func testViewModelDuplicateScanSuppression() async {
        let mock = MockOpenFoodFactsService()
        let expectedItem = FoodItem(name: "Greek Yogurt", barcode: "55555")
        mock.stubbedResult = .success(expectedItem)

        let vm = BarcodeScannerViewModel(service: mock)
        vm.startScanning()

        await vm.processScannedBarcode("55555")
        XCTAssertEqual(mock.fetchProductCallCount, 1)

        // Try scanning the exact same barcode while already in success state
        await vm.processScannedBarcode("55555")
        XCTAssertEqual(mock.fetchProductCallCount, 1, "Duplicate scan while displaying success should be ignored")
    }

    @MainActor
    func testViewModelReset() async {
        let mock = MockOpenFoodFactsService()
        let expectedItem = FoodItem(name: "Apple", barcode: "77777")
        mock.stubbedResult = .success(expectedItem)

        let vm = BarcodeScannerViewModel(service: mock)
        await vm.processScannedBarcode("77777")

        XCTAssertNotNil(vm.scannedFoodItem)

        vm.reset()

        XCTAssertEqual(vm.state, .scanning)
        XCTAssertNil(vm.scannedFoodItem)
        XCTAssertNil(vm.errorMessage)
    }
}
