import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

public extension URLRequest {
    
    init(components: URLComponents) {
        guard let url = components.url else {
            preconditionFailure("Unable to get URL from URLComponents: \(components)")
        }
        
        self = Self(url: url)
            .add(headers: ["Content-Type": "application/json"])
    }
    
    private func map(_ transform: (inout Self) -> ()) -> Self {
        var request = self
        transform(&request)
        return request
    }
    
    func add(httpMethod: HTTPMethod) -> Self {
        map { $0.httpMethod = httpMethod.rawValue }
    }
    
    func add<Body: Encodable>(body: Body) -> Self {
        map {
            do {
                $0.httpBody = try JSONEncoder().encode(body)
            } catch {
                preconditionFailure("Failed to encode request Body: \(body) due to Error: \(error)")
            }
        }
    }
    
    func add(headers: [String: String]) -> Self {
        map {
            let allHTTPHeaderFields = $0.allHTTPHeaderFields ?? [:]
            
            let updatedAllHTTPHeaderFields = headers.merging(allHTTPHeaderFields, uniquingKeysWith: { $1 })
            $0.allHTTPHeaderFields = updatedAllHTTPHeaderFields
        }
    }
    
}
