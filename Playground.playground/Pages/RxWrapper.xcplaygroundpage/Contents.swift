//: [Previous](@previous)
PlaygroundPage.current.needsIndefiniteExecution = true
import PlaygroundSupport
import NetworkingTests
import RxSwift
import RxCocoa
PlaygroundPage.current.needsIndefiniteExecution = true

extension Reactive where Base: URLSession {
    func response<T>(request: URLRequest) -> Observable<T> where T: Decodable{
        return self.response(request: request)
            .map { response, data -> T in
                try data.decode(T.self)
        }
    }
    
    func response(request: URLRequest) -> Observable<Void> {
        return self.response(request: request)
            .map { _,_ in }
    }
}

public struct NetworkingContext {
    public var configuartion = URLSessionConfiguration.default
    public lazy var session: URLSession = URLSession(configuration: configuartion)
    public var cachePolicy = URLRequest.CachePolicy.returnCacheDataElseLoad
}

var context = NetworkingContext()


protocol SampleService {
    func fetch(batch: Int, ofSize size: Int) -> Observable<SampleResponseStruct>
}

struct Sample: SampleService {
    let scheme: String
    let urlHost: String
    let session: URLSession
    
    func fetch(batch: Int, ofSize size: Int) -> Observable<SampleResponseStruct> {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = urlHost
        urlComponents.path = "/api/v1/Wikis/List"
        urlComponents.queryItems = ["expand": "1",
                                    "batch": String(batch),
                                    "limit": String(size)].map(URLQueryItem.init)
        let url = urlComponents.url
        let request = URLRequest(url: url!)
        return session.rx.response(request: request)
    }
}

let disposeBag = DisposeBag()
let sample: SampleService = Sample(scheme: "https", urlHost: "wikia.com", session: context.session)
sample.fetch(batch: 1, ofSize: 1)
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

