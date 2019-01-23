PlaygroundPage.current.needsIndefiniteExecution = true
import PlaygroundSupport
import Moya
import RxSwift
import RxCocoa
import NetworkingTests

private func JSONResponseDataFormatter(_ data: Data) -> Data {
    do {
        let dataAsJSON = try JSONSerialization.jsonObject(with: data)
        let prettyData =  try JSONSerialization.data(withJSONObject: dataAsJSON, options: .prettyPrinted)
        return prettyData
    } catch {
        return data // fallback to original data if it can't be serialized.
    }
}

// MARK: - Provider support
private extension String {
    var urlEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

public enum Wiki {
    case list(batch: Int, limit: Int)
}

extension Wiki: TargetType {
    public var baseURL: URL {
        return URL(string: "https://wikia.com")!
    }
    public var path: String {
        switch self {
        case .list:
            return "/api/v1/Wikis/List"
        }
    }
    public var method: Moya.Method {
        return .get
    }
    public var task: Task {
        switch self {
        case .list(let batch, let limit):
            return .requestParameters(
                parameters: ["batch": batch,
                             "limit": limit],
                encoding: URLEncoding.default)
        }
    }
    
    public var validationType: ValidationType {
        switch self {
        case .list:
            return .successCodes
        }
    }
    public var sampleData: Data {
        switch self {
        case .list:
            return "Mock json here".data(using: String.Encoding.utf8)!
        }
    }
    public var headers: [String: String]? {
        return nil
    }
}


public func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}

protocol SampleService {
    func fetch(batch: Int, ofSize size: Int, @escaping completion: (Result<SampleResponseStruct, NSError>) -> Void)
}


// COMPLETION DOESN'T WORK SO ...


//struct Service: SampleService {
//    let apiClient: MoyaProvider<Wiki>
//    init(apiClient: MoyaProvider<Wiki> = MoyaProvider<Wiki>()) {
//        self.apiClient = apiClient
//    }
//
//    func fetch(batch: Int, ofSize size: Int, completion: (Result<SampleResponseStruct, NSError>) -> Void) {
//        return apiClient.request(<#T##target: Wiki##Wiki#>, completion: { (<#Result<Response, MoyaError>#>) in
//            <#code#>
//        })
//        return apiClient.request(.list(batch: batch, limit: size), completion: { result in
//            switch result {
//            case .success(let val):
//            case .failure(let failure):
//            }
//        })
//    }
//}

// RX
protocol SampleServiceRX{
    func fetch(batch: Int,
               ofSize size: Int) -> Observable<SampleResponseStruct>
}

public struct ServiceRX: SampleServiceRX {
    let apiClient: MoyaProvider<Wiki>
    init(apiClient: MoyaProvider<Wiki> = MoyaProvider<Wiki>()) {
        self.apiClient = apiClient
    }
    
    func fetch(batch: Int,
               ofSize size: Int) -> Observable<SampleResponseStruct> {
        return apiClient.rx.request(.list(batch: batch, limit: size))
            .filterSuccessfulStatusCodes()
            .map(SampleResponseStruct.self)
            .asObservable()
    }
}
let disposeBag = DisposeBag()
let service = ServiceRX()
service.fetch(batch: 1, ofSize: 1)
    .subscribe(onNext: { val in
        print(val)
    }, onError: { err in
        print(err)
    }, onCompleted: {
        print("completed")
    }, onDisposed: {
        print("disposed")
    })
    .disposed(by: disposeBag)

// THIS DOESN'T Work
// Moya is bad 💩
