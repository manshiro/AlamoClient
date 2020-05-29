//
//  ACProtocols.swift
//  ACProtocols
//
//  Created by CavanSu on 2019/6/19.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation

public protocol ACLogTube: NSObjectProtocol {
    func log(from: AnyClass, info: String, extral: String?, funcName: String)
    func log(from: AnyClass, warning: String, extral: String?, funcName: String)
    func log(from: AnyClass, error: Error, extral: String?, funcName: String)
}

public protocol AGERequestEvent: CustomStringConvertible {
    var name: String {get set}
}

public protocol AGERequestTaskProtocol {
    var id: Int {get set}
    var event: AGERequestEvent {get set}
    var requestType: RequestType {get set}
    var timeout: RequestTimeout {get set}
    var header: [String: String]? {get set}
    var parameters: [String: Any]? {get set}
}

public protocol AGEUploadTaskProtocol: AGERequestTaskProtocol {
    var object: UploadObject {get set}
}

// MARK: - Request APIs
public protocol RequestClientProtocol {
    func request(task: AGERequestTaskProtocol, responseOnMainQueue: Bool, success: AGEResponse?, failRetry: ErrorRetryCompletion)
    func upload(task: AGEUploadTaskProtocol, responseOnMainQueue: Bool, success: AGEResponse?, failRetry: ErrorRetryCompletion)
}
