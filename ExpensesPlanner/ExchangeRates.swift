import Foundation
import SwiftData

enum ExchangeRateOrigin: String, Codable {
    case network
    case manual
}

enum ExchangeRateRetrieval {
    case network
    case cache
    case manual
}

struct ExchangeRateResult: Equatable {
    let rateCOPPerCNY: Decimal
    let timestamp: Date
    let provider: String
    let source: String
    let origin: ExchangeRateOrigin
    let retrieval: ExchangeRateRetrieval
}

enum ExchangeRateError: Error, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case providerError(String)
    case unexpectedBaseCurrency(String?)
    case missingRate
    case invalidRate
    case missingProviderTimestamp
    case decoding
    case timeout
    case network
    case persistence
}

@Model
final class ExchangeRateSnapshot {
    @Attribute(.unique) var id: UUID
    private(set) var rateCOPPerCNY: Decimal
    private(set) var timestamp: Date
    private(set) var provider: String
    private(set) var source: String
    private(set) var origin: ExchangeRateOrigin

    init(
        id: UUID = UUID(),
        rateCOPPerCNY: Decimal,
        timestamp: Date,
        provider: String,
        source: String,
        origin: ExchangeRateOrigin
    ) throws {
        guard rateCOPPerCNY > .zero, rateCOPPerCNY.isFinite else {
            throw ExchangeRateError.invalidRate
        }

        self.id = id
        self.rateCOPPerCNY = rateCOPPerCNY
        self.timestamp = timestamp
        self.provider = provider
        self.source = source
        self.origin = origin
    }
}

protocol ExchangeRateTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionExchangeRateTransport: ExchangeRateTransport {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        session = URLSession(configuration: configuration)
    }

    init(session: URLSession) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

@MainActor
final class ExchangeRateService {
    static let endpoint = URL(string: "https://open.er-api.com/v6/latest/CNY")!
    static let providerAttribution = "https://www.exchangerate-api.com"
    static let manualProvider = "Manual entry"
    static let manualSource = "Local device"

    private let context: ModelContext
    private let transport: ExchangeRateTransport
    private let now: () -> Date

    init(
        context: ModelContext,
        transport: ExchangeRateTransport = URLSessionExchangeRateTransport(),
        now: @escaping () -> Date = { .now }
    ) {
        self.context = context
        self.transport = transport
        self.now = now
    }

    func refreshRate() async throws -> ExchangeRateResult {
        do {
            let freshRate = try await requestNetworkRate()
            let snapshot = try ExchangeRateSnapshot(
                rateCOPPerCNY: freshRate.rateCOPPerCNY,
                timestamp: freshRate.timestamp,
                provider: freshRate.provider,
                source: freshRate.source,
                origin: .network
            )
            try persist(snapshot)
            return freshRate
        } catch {
            if let cachedRate = try? latestCachedRate() {
                return cachedRate
            }
            throw error
        }
    }

    func latestCachedRate() throws -> ExchangeRateResult? {
        var descriptor = FetchDescriptor<ExchangeRateSnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        do {
            return try context.fetch(descriptor).first.map {
                result(for: $0, retrieval: .cache)
            }
        } catch {
            throw ExchangeRateError.persistence
        }
    }

    func saveManualRate(_ rateCOPPerCNY: Decimal) throws -> ExchangeRateResult {
        let snapshot = try ExchangeRateSnapshot(
            rateCOPPerCNY: rateCOPPerCNY,
            timestamp: now(),
            provider: Self.manualProvider,
            source: Self.manualSource,
            origin: .manual
        )
        try persist(snapshot)
        return result(for: snapshot, retrieval: .manual)
    }

    private func requestNetworkRate() async throws -> ExchangeRateResult {
        var request = URLRequest(
            url: Self.endpoint,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 15
        )
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch let error as URLError {
            throw error.code == .timedOut ? ExchangeRateError.timeout : .network
        } catch {
            throw ExchangeRateError.network
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ExchangeRateError.httpStatus(httpResponse.statusCode)
        }

        let providerResponse: ProviderResponse
        do {
            providerResponse = try JSONDecoder().decode(ProviderResponse.self, from: data)
        } catch {
            throw ExchangeRateError.decoding
        }

        guard providerResponse.result == "success" else {
            throw ExchangeRateError.providerError(
                providerResponse.errorType ?? providerResponse.result ?? "unknown"
            )
        }
        guard providerResponse.baseCode == "CNY" else {
            throw ExchangeRateError.unexpectedBaseCurrency(providerResponse.baseCode)
        }
        guard let timestamp = providerResponse.timeLastUpdateUnix, timestamp > 0 else {
            throw ExchangeRateError.missingProviderTimestamp
        }
        guard let providerRate = providerResponse.rates?["COP"] else {
            throw ExchangeRateError.missingRate
        }
        guard let rate = providerRate.decimal, rate > .zero, rate.isFinite else {
            throw ExchangeRateError.invalidRate
        }

        return ExchangeRateResult(
            rateCOPPerCNY: rate,
            timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
            provider: Self.providerAttribution,
            source: Self.endpoint.absoluteString,
            origin: .network,
            retrieval: .network
        )
    }

    private func persist(_ snapshot: ExchangeRateSnapshot) throws {
        context.insert(snapshot)
        do {
            try context.save()
        } catch {
            context.delete(snapshot)
            throw ExchangeRateError.persistence
        }
    }

    private func result(
        for snapshot: ExchangeRateSnapshot,
        retrieval: ExchangeRateRetrieval
    ) -> ExchangeRateResult {
        ExchangeRateResult(
            rateCOPPerCNY: snapshot.rateCOPPerCNY,
            timestamp: snapshot.timestamp,
            provider: snapshot.provider,
            source: snapshot.source,
            origin: snapshot.origin,
            retrieval: retrieval
        )
    }
}

private struct ProviderResponse: Decodable {
    let result: String?
    let baseCode: String?
    let timeLastUpdateUnix: Int?
    let rates: [String: ProviderRate]?
    let errorType: String?

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case timeLastUpdateUnix = "time_last_update_unix"
        case rates
        case errorType = "error-type"
    }
}

private struct ProviderRate: Decodable {
    let decimal: Decimal?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Decimal.self) {
            decimal = value
            return
        }

        if let value = try? container.decode(String.self) {
            switch value.lowercased() {
            case "nan":
                decimal = .nan
            case "inf", "+inf", "infinity", "+infinity", "-inf", "-infinity":
                decimal = nil
            default:
                guard let parsed = Decimal(
                    string: value,
                    locale: Locale(identifier: "en_US_POSIX")
                ) else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid decimal exchange rate"
                    )
                }
                decimal = parsed
            }
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Exchange rate must be a decimal number"
        )
    }
}
