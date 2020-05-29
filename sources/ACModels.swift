//
//  ACModels.swift
//  ACModels
//
//  Created by CavanSu on 2019/7/11.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation

public typealias DicCompletion = (([String: Any]) -> Void)?
public typealias AnyCompletion = ((Any?) -> Void)?
public typealias StringCompletion = ((String) -> Void)?
public typealias IntCompletion = ((Int) -> Void)?
public typealias Completion = (() -> Void)?

public typealias DicEXCompletion = (([String: Any]) throws -> Void)?
public typealias StringExCompletion = ((String) throws -> Void)?
public typealias DataExCompletion = ((Data) throws -> Void)?

public typealias ErrorCompletion = ((ACError) -> Void)?
public typealias ErrorBoolCompletion = ((ACError) -> Bool)?
public typealias ErrorRetryCompletion = ((ACError) -> RetryOptions)?

// MARK: enum
public enum RetryOptions {
    case retry(after: TimeInterval, newTask: AGERequestTaskProtocol? = nil), resign
}

public enum ACSwitch: Int, CustomStringConvertible {
    case off = 0, on = 1
    
    public var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    var boolValue: Bool {
        switch self {
        case .on:  return true
        case .off: return false
        }
    }
    
    var intValue: Int {
        switch self {
        case .on:  return 1
        case .off: return 0
        }
    }
    
    func cusDescription() -> String {
        switch self {
        case .on:  return "on"
        case .off: return "off"
        }
    }
}

public enum RequestType {
    case http(AGEHttpMethod, url: String), socket(peer: String)
    
    var httpMethod: AGEHttpMethod? {
        switch self {
        case .http(let method, _):  return method
        default:                    return nil
        }
    }
    
    var url: String? {
        switch self {
        case .http(_, let url):  return url
        default:                 return nil
        }
    }
}

public enum AGEResponse {
    case json(DicEXCompletion), data(DataExCompletion), blank(Completion)
}

public enum RequestTimeout {
    case low, medium, high, custom(TimeInterval)
    
    var value: TimeInterval {
        switch self {
        case .low:               return 20
        case .medium:            return 10
        case .high:              return 3
        case .custom(let value): return value
        }
    }
}

public enum FileMIME {
    case png, zip
    
    var text: String {
        switch self {
        case .png: return "image/png"
        case .zip: return "application/octet-stream"
        }
    }
}

// MARK: struct
public struct RequestEvent: AGERequestEvent {
    public var name: String
    
    public var description: String {
        return cusDescription()
    }
    
    public init(name: String) {
        self.name = name
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    func cusDescription() -> String {
        return name
    }
}

public struct UploadObject: CustomStringConvertible {
    var fileKeyOnServer: String
    var fileName: String
    var fileData: Data
    var mime: FileMIME
    
    public var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    func cusDescription() -> String {
        return ["fileKeyOnServer": fileKeyOnServer,
                "fileName": fileName,
                "mime": mime.text].description
    }
}

public struct RequestTask: AGERequestTaskProtocol {
    public var id: Int
    public var event: AGERequestEvent
    public var requestType: RequestType
    public var timeout: RequestTimeout
    public var header: [String : String]?
    public var parameters: [String : Any]?
    
    public init(event: AGERequestEvent,
         type: RequestType,
         timeout: RequestTimeout = .medium,
         header: [String: String]? = nil,
         parameters: [String: Any]? = nil) {
        TaskId.value += 1
        self.id = TaskId.value
        self.event = event
        self.requestType = type
        self.timeout = timeout
        self.header = header
        self.parameters = parameters
    }
}

public struct UploadTask: AGEUploadTaskProtocol, CustomStringConvertible {
    public var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    public var id: Int
    public var event: AGERequestEvent
    public var timeout: RequestTimeout
    public var url: String
    public var header: [String: String]?
    public var parameters: [String: Any]?
    
    public var object: UploadObject
    public var requestType: RequestType
    
    init(event: AGERequestEvent,
         timeout: RequestTimeout = .medium,
         object: UploadObject,
         url: String,
         fileData: Data,
         fileName: String,
         header: [String: String]? = nil,
         parameters: [String: Any]? = nil) {
        TaskId.value += 1
        self.id = TaskId.value
        self.url = url
        self.object = object
        self.requestType = .http(.post, url: url)
        self.event = event
        self.timeout = timeout
        self.header = header
        self.parameters = parameters
    }
    
    func cusDescription() -> String {
        let dic: [String: Any] = ["object": object.description,
                                  "header": OptionsDescription.any(header),
                                  "parameters": OptionsDescription.any(parameters)]
        return dic.description
    }
}

fileprivate struct TaskId {
    static var value: Int = Date.millisecondTimestamp
}

fileprivate extension Date {
    static var millisecondTimestamp: Int {
        return Int(CACurrentMediaTime() * 1000)
    }
}
