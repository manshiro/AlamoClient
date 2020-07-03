//
//  AlamoClient.swift
//  AlamoClient
//
//  Created by CavanSu on 2019/6/23.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Alamofire

public protocol AlamoClientDelegate: NSObjectProtocol {
    func alamo(_ client: AlamoClient, requestSuccess event: ACRequestEvent, startTime: TimeInterval, url: String)
    func alamo(_ client: AlamoClient, requestFail error: ACError, event: ACRequestEvent, url: String)
}

public class AlamoClient: NSObject, RequestClientProtocol {
    private lazy var instances = [Int: SessionManager]() // Int: taskId
    private lazy var afterWorkers = [String: AfterWorker]() // String: ACRequestEvent name
    
    private var responseQueue = DispatchQueue(label: "Alamo_Client_Response_Queue")
    private var afterQueue = DispatchQueue(label: "Alamo_Client_After_Queue")
    
    public weak var delegate: AlamoClientDelegate?
    public weak var logTube: ACLogTube?
    
    public init(delegate: AlamoClientDelegate? = nil,
                logTube: ACLogTube? = nil) {
        self.delegate = delegate
        self.logTube = logTube
    }
}

public extension AlamoClient {
    func getCookieArray()-> [HTTPCookie]? {
        let cookieStorage = HTTPCookieStorage.shared
        let cookieArray = cookieStorage.cookies
        return cookieArray
    }
    
    func insertCookie(_ cookie: HTTPCookie) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }
}

public extension AlamoClient {
    func request(task: ACRequestTaskProtocol, responseOnMainQueue: Bool = true, success: ACResponse? = nil, failRetry: ACErrorRetryCompletion = nil) {
        privateRequst(task: task, responseOnMainQueue: responseOnMainQueue, success: success) { [unowned self] (error) in
            guard let eRetry = failRetry else {
                self.removeWorker(of: task.event)
                return
            }
            
            let option = eRetry(error)
            switch option {
            case .retry(let time, let newTask):
                var reTask: ACRequestTaskProtocol
                
                if let newTask = newTask {
                    reTask = newTask
                } else {
                    reTask = task
                }
                
                let work = self.worker(of: reTask.event)
                work.perform(after: time, on: self.afterQueue, {
                    self.request(task: reTask, success: success, failRetry: failRetry)
                })
            case .resign:
                break
            }
        }
    }
    
    func upload(task: ACUploadTaskProtocol, responseOnMainQueue: Bool = true, success: ACResponse? = nil, failRetry: ACErrorRetryCompletion = nil) {
        privateUpload(task: task, success: success) { [unowned self] (error) in
            guard let eRetry = failRetry else {
                self.removeWorker(of: task.event)
                return
            }
            
            let option = eRetry(error)
            switch option {
            case .retry(let time, let newTask):
                var reTask: ACUploadTaskProtocol
                
                if let newTask = newTask as? ACUploadTaskProtocol {
                    reTask = newTask
                } else {
                    reTask = task
                }
                
                let work = self.worker(of: reTask.event)
                work.perform(after: time, on: self.afterQueue, {
                    self.upload(task: reTask, success: success, failRetry: failRetry)
                })
            case .resign:
                break
            }
        }
    }
}

// MARK: Request
public typealias AGEHttpMethod = HTTPMethod

extension HTTPMethod {
    fileprivate var encoding: ParameterEncoding {
        switch self {
        case .get:   return URLEncoding.default
        case .post:  return JSONEncoding.default
        default:     return JSONEncoding.default
        }
    }
}

private extension AlamoClient {
    func privateRequst(task: ACRequestTaskProtocol, responseOnMainQueue: Bool = true, success: ACResponse?, requestFail: ACErrorCompletion) {
        guard let httpMethod = task.requestType.httpMethod else {
            fatalError("Request Type error")
        }
        
        guard var url = task.requestType.url else {
            fatalError("Request Type error")
        }
        
        let timeout = task.timeout.value
        let taskId = task.id
        let startTime = Date.timeIntervalSinceReferenceDate
        let instance = alamo(timeout, id: taskId)
        
        var dataRequest: DataRequest
        
        if httpMethod == .get {
            if let parameters = task.parameters {
                url = urlAddParameters(url: url, parameters: parameters)
            }
            dataRequest = instance.request(url,
                                           method: httpMethod,
                                           encoding: httpMethod.encoding,
                                           headers: task.header)
        } else {
            dataRequest = instance.request(url,
                                           method: httpMethod,
                                           parameters: task.parameters,
                                           encoding: httpMethod.encoding,
                                           headers: task.header)
        }
        
        log(info: "http request, event: \(task.event.description)",
            extra: "url: \(url), parameter: \(OptionsDescription.any(task.parameters))")
        
        var queue: DispatchQueue
        if responseOnMainQueue {
            queue = DispatchQueue.main
        } else {
            queue = responseQueue
        }
        
        dataRequest.responseData(queue: queue) { [unowned self] (dataResponse) in
            self.handle(dataResponse: dataResponse,
                        from: task,
                        url: url,
                        startTime: startTime,
                        success: success,
                        fail: requestFail)
            self.removeInstance(taskId)
            self.removeWorker(of: task.event)
        }
    }
    
    func privateUpload(task: ACUploadTaskProtocol, responseOnMainQueue: Bool = true, success: ACResponse?, requestFail: ACErrorCompletion) {
        guard let _ = task.requestType.httpMethod else {
            fatalError("Request Type error")
        }
        
        guard let url = task.requestType.url else {
            fatalError("Request Type error")
        }
        
        let timeout = task.timeout.value
        let taskId = task.id
        let startTime = Date.timeIntervalSinceReferenceDate
        let instance = alamo(timeout, id: taskId)
        
        log(info: "http upload, event: \(task.event.description)",
            extra: "url: \(url), parameter: \(OptionsDescription.any(task.parameters))")
        
        var queue: DispatchQueue
        if responseOnMainQueue {
            queue = DispatchQueue.main
        } else {
            queue = responseQueue
        }
        
        instance.upload(multipartFormData: { (multiData) in
            multiData.append(task.object.fileData,
                             withName: task.object.fileKeyOnServer,
                             fileName: task.object.fileName,
                             mimeType: task.object.mime.text)
            
            guard let parameters = task.parameters else {
                return
            }
            
            for (key, value) in parameters {
                if let stringValue = value as? String,
                    let part = stringValue.data(using: String.Encoding.utf8) {
                    multiData.append(part, withName: key)
                } else if var intValue = value as? Int {
                    let part = Data(bytes: &intValue, count: MemoryLayout<Int>.size)
                    multiData.append(part, withName: key)
                }
            }
        }, to: url, headers: task.header) { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.uploadProgress(queue: DispatchQueue.main, closure: { (progress) in
                })
                
                upload.responseData(queue: queue) { [unowned self] (dataResponse) in
                    self.handle(dataResponse: dataResponse,
                                from: task,
                                url: url,
                                startTime: startTime,
                                success: success,
                                fail: requestFail)
                    self.removeInstance(taskId)
                    self.removeWorker(of: task.event)
                }
            case .failure(let error):
                let mError = ACError.fail(error.localizedDescription)
                self.request(error: mError, of: task.event, with: url)
                if let requestFail = requestFail {
                    requestFail(mError)
                }
                self.removeInstance(taskId)
            }
        }
    }
    
    func handle(dataResponse: DataResponse<Data>, from task: ACRequestTaskProtocol, url: String, startTime: TimeInterval, success: ACResponse?, fail: ACErrorCompletion) {
        let result = self.checkResponseData(dataResponse, event: task.event)
        switch result {
        case .pass(let data):
            self.requestSuccess(of: task.event, startTime: startTime, with: url)
            guard let success = success else {
                break
            }
            
            do {
                switch success {
                case .blank(let completion):
                    self.log(info: "request success", extra: "event: \(task.event)")
                    guard let completion = completion else {
                        break
                    }
                    completion()
                case .data(let completion):
                    self.log(info: "request success", extra: "event: \(task.event), data.count: \(data.count)")
                    guard let completion = completion else {
                        break
                    }
                    try completion(data)
                case .json(let completion):
                    let json = try data.json()
                    self.log(info: "request success", extra: "event: \(task.event), json: \(json.description)")
                    guard let completion = completion else {
                        break
                    }
                    
                    try completion(json)
                }
            } catch let error as ACError {
                if let fail = fail {
                    fail(error)
                }
                self.log(error: error, extra: "event: \(task.event)")
            } catch {
                if let fail = fail {
                    fail(ACError.unknown())
                }
                self.log(error: ACError.unknown(), extra: "event: \(task.event)")
            }
        case .fail(let error):
            self.request(error: error, of: task.event, with: url)
            self.log(error: error, extra: "event: \(task.event), url: \(url)")
            if let fail = fail {
                fail(error)
            }
        }
    }
}

// MARK: Alamo instance
private extension AlamoClient {
    func alamo(_ timeout: TimeInterval, id: Int) -> SessionManager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = timeout
        
        let alamo = Alamofire.SessionManager(configuration: configuration)
        instances[id] = alamo
        return alamo
    }
    
    func removeInstance(_ id: Int) {
        instances.removeValue(forKey: id)
    }
        
    func urlAddParameters(url: String, parameters: [String: Any]) -> String {
        var fullURL = url
        var index: Int = 0

        for (key, value) in parameters {
            if index == 0 {
                fullURL += "?"
            } else {
                fullURL += "&"
            }
            
            fullURL += "\(key)=\(value)"
            index += 1
        }
        return fullURL
    }
    
    func worker(of event: ACRequestEvent) -> AfterWorker {
        var work: AfterWorker
        if let tWork = self.afterWorkers[event.name] {
            work = tWork
        } else {
            work = AfterWorker()
        }
        return work
    }
    
    func removeWorker(of event: ACRequestEvent) {
        afterWorkers.removeValue(forKey: event.name)
    }
}

// MARK: Check Response
private extension AlamoClient {
    enum ResponseCode {
        init(rawValue: Int) {
            if rawValue == 200 {
                self = .success
            } else {
                self = .error(code: rawValue)
            }
        }
        
        case success, error(code: Int)
    }
    
    enum CheckResult {
        case pass, fail(ACError)
        
        var rawValue: Int {
            switch self {
            case .pass: return 0
            case .fail: return 1
            }
        }
        
        static func ==(left: CheckResult, right: CheckResult) -> Bool {
            return left.rawValue == right.rawValue
        }
        
        static func !=(left: CheckResult, right: CheckResult) -> Bool {
            return left.rawValue != right.rawValue
        }
    }
    
    enum CheckDataResult {
        case pass(Data), fail(ACError)
    }
    
    func checkResponseData(_ dataResponse: DataResponse<Data>, event: ACRequestEvent) -> CheckDataResult {
        var dataResult: CheckDataResult = .fail(ACError.unknown())
        var result: CheckResult = .fail(ACError.unknown())
        let code = dataResponse.response?.statusCode
        let checkIndexs = 3
        
        for index in 0 ..< checkIndexs {
            switch index {
            case 0:  result = checkResponseCode(code, event: event)
            case 1:  result = checkResponseContent(dataResponse.error, event: event)
            case 2:
                if let data = dataResponse.data {
                    dataResult = .pass(data)
                } else {
                    let error =  ACError.fail("response data nil",
                                               extra: "return data nil, event: \(event.description)")
                    dataResult = .fail(error)
                }
            default: break
            }
            
            var isBreak = false
            
            switch result {
            case .fail(let error): dataResult = .fail(error); isBreak = true;
            case .pass: break
            }
            
            if isBreak {
                break
            }
        }
        
        return dataResult
    }
    
    func checkResponseCode(_ code: Int?, event: ACRequestEvent) -> CheckResult {
        var result: CheckResult = .pass
        
        if let code = code {
            let mCode = ResponseCode(rawValue: code)
            
            switch mCode {
            case .success:
                result = .pass
            case .error(let code):
                let error = ACError.fail("response code error",
                                          code: code,
                                          extra: "event: \(event.description)")
                result = .fail(error)
            }
        } else {
            let error = ACError.fail("connect with server error, response code nil",
                                      extra: "event: \(event.description)")
            result = .fail(error)
        }
        return result
    }
    
    func checkResponseContent(_ error: Error?, event: ACRequestEvent) -> CheckResult {
        var result: CheckResult = .pass
        
        if let error = error as? AFError {
            let mError = ACError.fail(error.localizedDescription,
                                       code: error.responseCode,
                                       extra: "event: \(event.description)")
            result = .fail(mError)
        } else if let error = error {
            let mError = ACError.fail(error.localizedDescription,
                                       extra: "event: \(event.description)")
            result = .fail(mError)
        }
        return result
    }
}

// MARK: Callback
private extension AlamoClient {
    func requestSuccess(of event: ACRequestEvent, startTime: TimeInterval, with url: String) {
        self.delegate?.alamo(self, requestSuccess: event, startTime: startTime, url: url)
    }
    
    func request(error: ACError, of event: ACRequestEvent, with url: String) {
        self.delegate?.alamo(self, requestFail: error, event: event, url: url)
    }
}

// MARK: Log
private extension AlamoClient {
    func log(info: String, extra: String? = nil, funcName: String = #function) {
        logTube?.log(from: AlamoClient.self, info: info, extral: extra, funcName: funcName)
    }
    
    func log(warning: String, extra: String? = nil, funcName: String = #function) {
        logTube?.log(from: AlamoClient.self, warning: warning, extral: extra, funcName: funcName)
    }
    
    func log(error: Error, extra: String? = nil, funcName: String = #function) {
        logTube?.log(from: AlamoClient.self, error: error, extral: extra, funcName: funcName)
    }
}

// MARK: extension
fileprivate extension Data {
    func json() throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: self, options: [])
        guard let dic = object as? [String: Any] else {
            throw ACError.convert("Any", "[String: Any]")
        }
        
        return dic
    }
}
