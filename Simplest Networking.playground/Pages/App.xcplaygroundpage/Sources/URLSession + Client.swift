import Foundation
import Combine

public extension URLSession {
    
    func fetch<Response: Decodable>(for request: URLRequest,
                                    with type: Response.Type) -> AnyPublisher<Response, Error> {
        dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: type, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
}
