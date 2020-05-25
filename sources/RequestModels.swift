//
//  RequestModels.swift
//  RequestModels
//
//  Created by CavanSu on 2019/7/11.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation

// MARK: enum
enum RequestType {
    case http(AGEHttpMethod, url: String), rtm(peer: String)
    
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

enum AGEResponse {
    case json(DicEXCompletion), data(DataExCompletion), blank(Completion)
}

enum RequestTimeout {
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

enum FileMIME {
    case png, zip
    
    var text: String {
        switch self {
        case .png: return "image/png"
        case .zip: return "application/octet-stream"
        }
    }
}

// MARK: struct
struct RequestEvent: AGERequestEvent {
    var name: String
    
    var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    func cusDescription() -> String {
        return name
    }
}

struct UploadObject: AGEDescription {
    var fileKeyOnServer: String
    var fileName: String
    var fileData: Data
    var mime: FileMIME
    
    var description: String {
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

struct RequestTask: AGERequestTaskProtocol {
    var id: Int
    var event: AGERequestEvent
    var requestType: RequestType
    var timeout: RequestTimeout
    var header: [String : String]?
    var parameters: [String : Any]?
    
    init(event: AGERequestEvent,
         type: RequestType,
         timeout: RequestTimeout = .medium,
         header: [String: String]? = nil,
         parameters: [String: Any]? = nil) {
        self.id = Date.millisecondTimestamp
        self.event = event
        self.requestType = type
        self.timeout = timeout
        self.header = header
        self.parameters = parameters
    }
}

struct UploadTask: AGEUploadTaskProtocol, AGEDescription {
    var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    var id: Int
    var event: AGERequestEvent
    var timeout: RequestTimeout
    var url: String
    var header: [String: String]?
    var parameters: [String: Any]?
    
    var object: UploadObject
    var requestType: RequestType
    
    init(event: AGERequestEvent,
         timeout: RequestTimeout = .medium,
         object: UploadObject,
         url: String,
         fileData: Data,
         fileName: String,
         header: [String: String]? = nil,
         parameters: [String: Any]? = nil) {
        self.id = Date.millisecondTimestamp
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
