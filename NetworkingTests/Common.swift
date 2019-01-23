//
//  Common.swift
//  NetworkingTests
//
//  Created by Patryk Mikolajczyk on 1/23/19.
//  Copyright © 2019 Patryk Mikolajczyk. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya

// SWIFT 5 enum
// from https://github.com/apple/swift-evolution/blob/master/proposals/0235-add-result.md
public enum Result<Value, Error: Swift.Error> {
    case value(Value), error(Error)
}

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}


extension JSONDecoder {
    static let current: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .current
        return decoder
    }()
}

extension JSONDecoder.DateDecodingStrategy {
    static let current: JSONDecoder.DateDecodingStrategy = .iso8601
}

extension JSONDecoder.DateDecodingStrategy {
    static let mock: JSONDecoder.DateDecodingStrategy = .iso8601
}

extension JSONEncoder {
    static let current: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .current
        return encoder
    }()
}

public extension Encodable {
    public var encoded: Data? {
        return try? JSONEncoder.current.encode(self)
    }
}

extension JSONEncoder.DateEncodingStrategy {
    static let current: JSONEncoder.DateEncodingStrategy = .iso8601
}

extension JSONEncoder.DateEncodingStrategy {
    static let mock: JSONEncoder.DateEncodingStrategy = .iso8601
}

public extension Data {
    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        return try JSONDecoder.current.decode(type, from: self)
    }
}

public typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void

public protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

extension URLSession: URLSessionProtocol {
    public func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask
    }
}

public protocol URLSessionDataTaskProtocol {
    var originalRequest: URLRequest? { get }
    func resume()
    func cancel()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}


