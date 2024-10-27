//
//  NetworkService.swift
//  UIKitMVVMCombineDemo
//
//  Created by PM on 25/10/2024.
//

import Foundation
import Combine
enum NetworkError: Error {
    case badURL, decodingError, unknown
}

// NetworkService
class NetworkService {
    static let shared = NetworkService()
    private let timeoutInterval: TimeInterval = 15.0
    
    func fetchPosts(page: Int, limit: Int) -> AnyPublisher<[Post], NetworkError> {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts?_page=\(page)&_limit=\(limit)")
                
        else {
            return Fail(error: NetworkError.badURL).eraseToAnyPublisher()
        }
        print("call url: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET" // Specify the request type as GET
        request.timeoutInterval = timeoutInterval
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                // Check for a successful HTTP status code (200-299)
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                return result.data
            }
            .decode(type: [Post].self, decoder: JSONDecoder())
            .mapError { _ in NetworkError.decodingError }
            .eraseToAnyPublisher()
    }
}
