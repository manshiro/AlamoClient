//
//  ACModels.swift
//  ACModels
//
//  Created by CavanSu on 2019/7/11.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation

public typealias ACDicCompletion = (([String: Any]) -> Void)?
public typealias ACAnyCompletion = ((Any?) -> Void)?
public typealias ACStringCompletion = ((String) -> Void)?
public typealias ACIntCompletion = ((Int) -> Void)?
public typealias ACCompletion = (() -> Void)?

public typealias ACDicEXCompletion = (([String: Any]) throws -> Void)?
public typealias ACStringExCompletion = ((String) throws -> Void)?
public typealias ACDataExCompletion = ((Data) throws -> Void)?

public typealias ACErrorCompletion = ((Error) -> Void)?
public typealias ACErrorBoolCompletion = ((Error) -> Bool)?
public typealias ACErrorRetryCompletion = ((Error) -> RetryOptions)?

// MARK: enum
public enum RetryOptions {
    case retry(after: TimeInterval, newTask: ACRequestTaskProtocol? = nil), resign
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

public enum ACResponse {
    case json(ACDicEXCompletion), data(ACDataExCompletion), blank(ACCompletion)
}

public enum ACRequestTimeout {
    case low, medium, high, custom(TimeInterval)
    
    public var value: TimeInterval {
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
    
    public var text: String {
        switch self {
        case .png: return "image/png"
        case .zip: return "application/octet-stream"
        }
    }
}

// MARK: struct
public struct RequestEvent: ACRequestEvent {
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
    public var fileKeyOnServer: String
    public var fileName: String
    public var fileData: Data
    public var mime: FileMIME
    
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

public struct RequestTask: ACRequestTaskProtocol {
    public var id: Int
    public var event: ACRequestEvent
    public var requestType: RequestType
    public var timeout: ACRequestTimeout
    public var header: [String : String]?
    public var parameters: [String : Any]?
    
    public init(event: ACRequestEvent,
         type: RequestType,
         timeout: ACRequestTimeout = .medium,
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

public struct UploadTask: ACUploadTaskProtocol, CustomStringConvertible {
    public var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    public var id: Int
    public var event: ACRequestEvent
    public var timeout: ACRequestTimeout
    public var url: String
    public var header: [String: String]?
    public var parameters: [String: Any]?
    
    public var object: UploadObject
    public var requestType: RequestType
    
    init(event: ACRequestEvent,
         timeout: ACRequestTimeout = .medium,
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
