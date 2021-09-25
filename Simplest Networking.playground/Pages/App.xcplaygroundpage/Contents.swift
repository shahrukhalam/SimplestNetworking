
/// ----- URLComponents -----
extension URLComponents {
    
    static var users: Self {
        Self(path: "/users")
    }
    
    static func userDetail(id: String) -> Self {
        let queryItems: [URLQueryItem] = [.init(name: "id", value: id)]
        return Self(path: "/user", queryItems: queryItems)
    }
    
}

/// ----- URLRequest -----
struct DetailRequestBody: Encodable {
    let name: String
}

extension URLRequest {
    
    static var users: Self {
        Self(components: .users)
    }
    
    static func userDetail(id: String, body: DetailRequestBody, accessToken: String) -> Self {
        Self(components: .userDetail(id: id))
            .add(httpMethod: .post)
            .add(body: body)
            .add(headers: ["accessToken": accessToken])
    }
    
}

/// ----- URLRequest Usage -----
let detailURLRequest: URLRequest = .userDetail(id: "1",
                                               body: DetailRequestBody(name: "SA"),
                                               accessToken: "123")
detailURLRequest.url
detailURLRequest.httpMethod
detailURLRequest.httpBody
detailURLRequest.allHTTPHeaderFields

/// ----- URLSession Usage -----
struct DetailResponse: Decodable, Equatable {
    let name: String
}

let request: URLRequest = .userDetail(id: "1",
                                      body: DetailRequestBody(name: "SA"),
                                      accessToken: "123")
let responsePublisher = URLSession.shared.fetch(for: request, with: DetailResponse.self)
let cancellable = responsePublisher.sink { completion in
     print(completion) // It's only for demonstration purpose; will fail as we are not hitting real API
} receiveValue: { response in
     print(response)
}

/// ----- Testing -----
import Combine
import XCTest

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    /// Determines whether the protocol subclass can handle the specified request
    /// In our case, we allow all the requests
    /// - Parameter request: URLRequest
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    /// Returns a canonical version of the specified request
    /// In our case, we don't need to modify the input request
    /// - Parameter request: URLRequest
    /// - Returns: Canonical URLRequest
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    /// Starts protocol-specific loading of the request
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
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
    
    /// Stops protocol-specific loading of the request
    /// In our case, we don't do anything
    override func stopLoading() {  }
}

class NetworkingTests: XCTestCase {
    
    var urlSession: URLSession!
    var cancellable: AnyCancellable!
    
    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
    }
    
    func testUsers() {
        let request: URLRequest = .users
        let mockJSONData = "[{\"name\":\"SA\"}]".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.path, "/users")
            return (HTTPURLResponse(), mockJSONData)
        }
        
        let expectation = XCTestExpectation(description: "Users")
        let responsePublisher = urlSession.fetch(for: request, with: [DetailResponse].self)
        cancellable = responsePublisher.sink { _ in } receiveValue: { response in
            XCTAssertEqual(response, [DetailResponse(name: "SA")])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
}

NetworkingTests.defaultTestSuite.run()
