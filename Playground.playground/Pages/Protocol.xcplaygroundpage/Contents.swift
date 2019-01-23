
import PlaygroundSupport
import NetworkingTests
PlaygroundPage.current.needsIndefiniteExecution = true

public protocol ServiceRequest {
    var urlScheme: String { get }
    var urlHost: String { get }
    var urlPath: String { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var timeoutInterval: TimeInterval { get }
    var allowsCellularAccess: Bool { get }
    var httpMethod: HTTPMethod { get }
    var allHTTPHeaderFields: [String: String]? { get }
    var httpBody: Data? { get }
    var urlParams: [String: String]? { get }
}
public extension ServiceRequest {
    var urlScheme: String {
        return "https"
    }
    
    var cachePolicy: URLRequest.CachePolicy {
        return URLRequest.CachePolicy.returnCacheDataElseLoad
    }
    
    var timeoutInterval: TimeInterval {
        return 10
    }
    
    var allowsCellularAccess: Bool {
        return true
    }
    
    var httpMethod: HTTPMethod {
        return HTTPMethod.get
    }
    
    var allHTTPHeaderFields: [String: String]? {
        return nil
    }
    
    var httpBody: Data? {
        if let params = jsonParams {
            return try? JSONSerialization.data(withJSONObject: params)
        }
        return stringParams?.data(using: .utf8)
    }
    
    var urlParams: [String: String]? {
        return nil
    }
    
    var jsonParams: [String: Any]? {
        return nil
    }
    
    var stringParams: String? {
        return nil
    }
    
    private var url: URL {
        var components = URLComponents()
        components.scheme = urlScheme
        components.host = urlHost
        components.path = urlPath
        components.queryItems = urlParams?.map(URLQueryItem.init)
        return components.url!
    }
    
    var request: URLRequest {
        var req = URLRequest(url: url)
        req.cachePolicy = cachePolicy
        req.timeoutInterval = timeoutInterval
        req.allowsCellularAccess = allowsCellularAccess
        req.httpMethod = httpMethod.rawValue
        req.allHTTPHeaderFields = allHTTPHeaderFields
        req.httpBody = httpBody
        return req
    }
}

extension ServiceRequest {
    public var curlString: String {
        var baseCommand = "curl \(url.absoluteString)"
        
        let method = httpMethod.rawValue
        
        if method == "HEAD" {
            baseCommand += " --head"
        }
        
        var command = [baseCommand]
        
        if method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }
        
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }
        
        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }
        
        return command.joined(separator: " \n\t ")
    }
}

public protocol ServiceType {
    var session: URLSessionProtocol { get }
}

public extension ServiceType {
    
    @discardableResult
    func get(service: ServiceRequest, completion: @escaping (Result<Void, NSError>) -> Void) -> URLSessionDataTaskProtocol {
        let task = session
            .dataTask(with: service.request) { (_, response, responseError) in
                completion(self.handleVoidResponse(response: response, responseError: responseError))
        }
        task.resume()
        return task
    }
    
    private func handleVoidResponse(response: URLResponse?, responseError: Error?) -> Result<Void, NSError> {
        if let error = responseError {
            return .error(error as NSError)
        }
        if let code = (response as? HTTPURLResponse)?.statusCode, code == 200 {
            return .value(())
        }
        return .error(NSError(domain: "NetworkingError", code: 400, userInfo: nil))
    }
    
    @discardableResult
    func get<T>(service: ServiceRequest, completion: @escaping (Result<T, NSError>) -> Void) -> URLSessionDataTaskProtocol where T: Decodable {
        let task = session
            .dataTask(with: service.request) { (responseData, response, responseError) in
                completion(self.handleResponse(responseData: responseData, response: response, responseError: responseError))
        }
        task.resume()
        return task
    }
    
    private func handleResponse<T>(responseData: Data?, response: URLResponse?, responseError: Error?) -> Result<T, NSError> where T: Decodable {
        if let error = responseError {
            return .error(error as NSError)
        }
        guard let jsonData = responseData else {
            let error = NSError(domain: "NetworkingError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Data was not retrieved from request"]) as Error
            return .error(error as NSError)
        }
        do {
            return .value(try jsonData.decode(T.self))
        } catch {
            return .error(error as NSError)
        }
    }
}


// CALL

struct SampleRequest {}
extension SampleRequest {
    struct Request: ServiceRequest {
        let limit: Int
        let batch: Int
        let urlHost: String
    }
}

extension SampleRequest.Request {
    var urlPath: String {
        return "/api/v1/Wikis/List"
    }
    
    var urlParams: [String: String]? {
        return ["expand": "1",
                "batch": String(batch),
                "limit": String(limit)]
    }
}

protocol SampleService {
    func fetch(batch: Int,
               ofSize size: Int,
               completion: @escaping (Result<SampleResponseStruct, NSError>) -> Void)
}

public struct NetworkingContext {
    public var configuartion = URLSessionConfiguration.default
    public lazy var session: URLSessionProtocol = URLSession(configuration: configuartion)
    public var cachePolicy = URLRequest.CachePolicy.returnCacheDataElseLoad
}

var context = NetworkingContext()

struct Servcie: ServiceType {
    let session: URLSessionProtocol = context.session
    let urlHost: String = "wikia.com"
    var tasks: [URL: URLSessionDataTaskProtocol] = [:]
}

extension Servcie: SampleService {
    
    func fetch(batch: Int,
               ofSize size: Int,
               completion: @escaping (Result<SampleResponseStruct, NSError>) -> Void) {
        let request = SampleRequest.Request.init(limit: size, batch: batch, urlHost: urlHost)
        self.get(service: request, completion: completion)
    }
}

struct ServiceMock: SampleService {
    func fetch(batch: Int,
               ofSize size: Int,
               completion: @escaping (Result<SampleResponseStruct, NSError>) -> Void) {
        completion(Result.value(.mock))
    }
}

let service = Servcie()

service.fetch(batch: 1, ofSize: 1) { res in
    switch res {
    case .value(let payload):
        print(payload)
    case .error(let error):
        print(error)
    }
}
