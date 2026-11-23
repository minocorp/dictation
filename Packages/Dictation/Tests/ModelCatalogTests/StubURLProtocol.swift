import Foundation
import Synchronization

internal final class StubURLProtocol: URLProtocol {
    typealias Route = @Sendable (URLRequest) -> StubReply

    private static let routes = Mutex<[String: Route]>([:])

    static func serve(repo: String, route: @escaping Route) {
        routes.withLock { $0[repo] = route }
    }

    override static func canInit(with request: URLRequest) -> Bool { true }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let repo = request.url.map {
            $0.pathComponents.dropFirst().prefix(2).joined(separator: "/")
        }
        let route = repo.flatMap { name in Self.routes.withLock { $0[name] } }
        let reply = route?(request) ?? .status(404)
        deliver(reply)
    }

    override func stopLoading() {}

    private func deliver(_ reply: StubReply) {
        guard let url = request.url else { return }
        switch reply {
        case .body(let data):
            respond(url: url, data: data, delivered: data.count, finishes: true)
        case .stalled(let data, let deliveredBytes):
            respond(url: url, data: data, delivered: deliveredBytes, finishes: false)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case .status(let code):
            let response = HTTPURLResponse(
                url: url,
                statusCode: code,
                httpVersion: "HTTP/1.1",
                headerFields: [:],
            )
            if let response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    private func respond(url: URL, data: Data, delivered: Int, finishes: Bool) {
        let range = rangeStart(of: request)
        let body = data.dropFirst(range ?? 0)
        var headers = [
            "Content-Length": "\(body.count)",
            "ETag": "\"stub\"",
            "Last-Modified": "Wed, 21 Oct 2015 07:28:00 GMT",
            "Accept-Ranges": "bytes",
        ]
        if let range {
            headers["Content-Range"] = "bytes \(range)-\(data.count - 1)/\(data.count)"
        }
        let response = HTTPURLResponse(
            url: url,
            statusCode: range == nil ? 200 : 206,
            httpVersion: "HTTP/1.1",
            headerFields: headers,
        )
        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: Data(body.prefix(delivered)))
        if finishes {
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    private func rangeStart(of request: URLRequest) -> Int? {
        guard let header = request.value(forHTTPHeaderField: "Range"),
            header.hasPrefix("bytes=")
        else { return nil }
        return Int(header.dropFirst("bytes=".count).prefix { $0 != "-" })
    }
}
