import Foundation
import SwiftData
import XCTest
@testable import ExpensesPlanner

private typealias TransportResponse = (Data, URLResponse)

private final class MockExchangeRateTransport: ExchangeRateTransport {
    private var result: Result<TransportResponse, Error>
    private(set) var requests: [URLRequest] = []

    init(result: Result<TransportResponse, Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> TransportResponse {
        requests.append(request)
        return try result.get()
    }
}

@MainActor
final class ExchangeRateTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try FinanceModelContainer.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testRefreshDecodesDecimalRateAndProviderTimestampWithFixedPrivateRequest() async throws {
        let transport = MockExchangeRateTransport(result: .success(response(json: successJSON())))
        let service = makeService(transport: transport)

        let result = try await service.refreshRate()

        XCTAssertEqual(result.rateCOPPerCNY, Decimal(string: "4012.345678")!)
        XCTAssertEqual(result.timestamp, Date(timeIntervalSince1970: 1_767_225_600))
        XCTAssertEqual(result.provider, "https://www.exchangerate-api.com")
        XCTAssertEqual(result.source, "https://open.er-api.com/v6/latest/CNY")
        XCTAssertEqual(result.origin, .network)
        XCTAssertEqual(result.retrieval, .network)

        let request = try XCTUnwrap(transport.requests.first)
        XCTAssertEqual(transport.requests.count, 1)
        XCTAssertEqual(request.url?.absoluteString, "https://open.er-api.com/v6/latest/CNY")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
        XCTAssertNil(request.httpBodyStream)
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(request.timeoutInterval, 15)

        let snapshots = try context.fetch(FetchDescriptor<ExchangeRateSnapshot>())
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.rateCOPPerCNY, result.rateCOPPerCNY)
        XCTAssertEqual(snapshots.first?.timestamp, result.timestamp)
    }

    func testRefreshRejectsProviderError() async {
        await assertRefreshError(
            .providerError("unsupported-code"),
            json: #"{"result":"error","error-type":"unsupported-code"}"#
        )
    }

    func testRefreshRejectsWrongBaseCurrency() async {
        await assertRefreshError(
            .unexpectedBaseCurrency("USD"),
            json: successJSON(base: #""USD""#)
        )
    }

    func testRefreshRejectsMissingRate() async {
        await assertRefreshError(.missingRate, json: successJSON(rates: "{}"))
    }

    func testRefreshRejectsNonpositiveRates() async {
        await assertRefreshError(.invalidRate, json: successJSON(rate: "0"))
        await assertRefreshError(.invalidRate, json: successJSON(rate: "-1.25"))
    }

    func testRefreshRejectsNonfiniteRates() async {
        await assertRefreshError(.invalidRate, json: successJSON(rate: #""NaN""#))
        await assertRefreshError(.invalidRate, json: successJSON(rate: #""Infinity""#))
    }

    func testRefreshRejectsMissingProviderTimestamp() async {
        await assertRefreshError(
            .missingProviderTimestamp,
            json: successJSON(timestamp: "null")
        )
    }

    func testRefreshRejectsMalformedResponse() async {
        await assertRefreshError(.decoding, json: #"{"result":"success""#)
    }

    func testRefreshRejectsHTTPError() async {
        let transport = MockExchangeRateTransport(
            result: .success(response(json: "{}", statusCode: 429))
        )
        let service = makeService(transport: transport)

        await assertRefreshError(.httpStatus(429), service: service)
    }

    func testRefreshMapsTimeoutAndNetworkFailures() async {
        let timeoutService = makeService(
            transport: MockExchangeRateTransport(
                result: .failure(URLError(.timedOut))
            )
        )
        await assertRefreshError(.timeout, service: timeoutService)

        let networkService = makeService(
            transport: MockExchangeRateTransport(
                result: .failure(URLError(.notConnectedToInternet))
            )
        )
        await assertRefreshError(.network, service: networkService)
    }

    func testLatestCachedRateSelectsNewestSnapshot() async throws {
        try insertSnapshot(rate: Decimal(3_900), day: 1)
        let newestID = try insertSnapshot(rate: Decimal(4_100), day: 3)
        try insertSnapshot(rate: Decimal(4_000), day: 2)
        try context.save()
        let service = makeService(
            transport: MockExchangeRateTransport(
                result: .failure(URLError(.notConnectedToInternet))
            )
        )

        let cached = try XCTUnwrap(service.latestCachedRate())

        XCTAssertEqual(cached.rateCOPPerCNY, Decimal(4_100))
        XCTAssertEqual(cached.timestamp, date(day: 3))
        XCTAssertEqual(cached.origin, .network)
        XCTAssertEqual(cached.retrieval, .cache)
        let snapshots = try context.fetch(FetchDescriptor<ExchangeRateSnapshot>())
        XCTAssertEqual(snapshots.first { $0.id == newestID }?.rateCOPPerCNY, Decimal(4_100))
    }

    func testFailedRefreshFallsBackToNewestRateAndPreservesEntireCache() async throws {
        let olderID = try insertSnapshot(rate: Decimal(3_900), day: 1)
        let newestID = try insertSnapshot(rate: Decimal(4_100), day: 2)
        try context.save()
        let service = makeService(
            transport: MockExchangeRateTransport(
                result: .failure(URLError(.notConnectedToInternet))
            )
        )

        let result = try await service.refreshRate()

        XCTAssertEqual(result.rateCOPPerCNY, Decimal(4_100))
        XCTAssertEqual(result.timestamp, date(day: 2))
        XCTAssertEqual(result.retrieval, .cache)
        let snapshots = try context.fetch(FetchDescriptor<ExchangeRateSnapshot>())
        XCTAssertEqual(snapshots.count, 2)
        XCTAssertEqual(Set(snapshots.map(\.id)), Set([olderID, newestID]))
        XCTAssertEqual(snapshots.first { $0.id == olderID }?.rateCOPPerCNY, Decimal(3_900))
        XCTAssertEqual(snapshots.first { $0.id == newestID }?.rateCOPPerCNY, Decimal(4_100))
    }

    func testManualRateUsesInjectedLocalClockAndPersistsMetadata() throws {
        let localTimestamp = date(day: 9)
        let service = makeService(
            transport: MockExchangeRateTransport(
                result: .failure(URLError(.notConnectedToInternet))
            ),
            now: localTimestamp
        )

        let result = try service.saveManualRate(Decimal(string: "4050.75")!)

        XCTAssertEqual(result.rateCOPPerCNY, Decimal(string: "4050.75")!)
        XCTAssertEqual(result.timestamp, localTimestamp)
        XCTAssertEqual(result.provider, "Manual entry")
        XCTAssertEqual(result.source, "Local device")
        XCTAssertEqual(result.origin, .manual)
        XCTAssertEqual(result.retrieval, .manual)
        let snapshot = try XCTUnwrap(context.fetch(FetchDescriptor<ExchangeRateSnapshot>()).first)
        XCTAssertEqual(snapshot.rateCOPPerCNY, result.rateCOPPerCNY)
        XCTAssertEqual(snapshot.timestamp, localTimestamp)
        XCTAssertEqual(snapshot.origin, .manual)
    }

    func testManualRateRejectsNonpositiveAndNonfiniteValuesWithoutSaving() throws {
        let service = makeService(
            transport: MockExchangeRateTransport(
                result: .failure(URLError(.notConnectedToInternet))
            )
        )

        for rate in [Decimal.zero, Decimal(-1), Decimal.nan] {
            XCTAssertThrowsError(try service.saveManualRate(rate)) { error in
                XCTAssertEqual(error as? ExchangeRateError, .invalidRate)
            }
        }
        XCTAssertEqual(try context.fetch(FetchDescriptor<ExchangeRateSnapshot>()).count, 0)
    }

    private func makeService(
        transport: MockExchangeRateTransport,
        now: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> ExchangeRateService {
        ExchangeRateService(context: context, transport: transport, now: { now })
    }

    private func assertRefreshError(
        _ expectedError: ExchangeRateError,
        json: String
    ) async {
        let service = makeService(
            transport: MockExchangeRateTransport(result: .success(response(json: json)))
        )
        await assertRefreshError(expectedError, service: service)
    }

    private func assertRefreshError(
        _ expectedError: ExchangeRateError,
        service: ExchangeRateService
    ) async {
        do {
            _ = try await service.refreshRate()
            XCTFail("Expected refresh to fail with \(expectedError)")
        } catch {
            XCTAssertEqual(error as? ExchangeRateError, expectedError)
        }
    }

    private func response(json: String, statusCode: Int = 200) -> TransportResponse {
        let response = HTTPURLResponse(
            url: ExchangeRateService.endpoint,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(json.utf8), response)
    }

    private func successJSON(
        rate: String = "4012.345678",
        timestamp: String = "1767225600",
        base: String = #""CNY""#,
        rates: String? = nil
    ) -> String {
        let rates = rates ?? "{\"COP\":\(rate)}"
        return #"{"result":"success","base_code":"# + base
            + #","time_last_update_unix":"# + timestamp
            + #","rates":"# + rates + "}"
    }

    @discardableResult
    private func insertSnapshot(rate: Decimal, day: Int) throws -> UUID {
        let snapshot = try ExchangeRateSnapshot(
            rateCOPPerCNY: rate,
            timestamp: date(day: day),
            provider: ExchangeRateService.providerAttribution,
            source: ExchangeRateService.endpoint.absoluteString,
            origin: .network
        )
        context.insert(snapshot)
        return snapshot.id
    }

    private func date(day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: 2026, month: 1, day: day))!
    }
}
