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

public protocol ACRequestEvent: CustomStringConvertible {
    var name: String {get set}
}

public protocol ACRequestTaskProtocol {
    var id: Int {get set}
    var event: ACRequestEvent {get set}
    var requestType: RequestType {get set}
    var timeout: ACRequestTimeout {get set}
    var header: [String: String]? {get set}
    var parameters: [String: Any]? {get set}
}

public protocol ACUploadTaskProtocol: ACRequestTaskProtocol {
    var object: UploadObject {get set}
}

// MARK: - Request APIs
public protocol RequestClientProtocol {
    func request(task: ACRequestTaskProtocol, responseOnMainQueue: Bool, success: ACResponse?, failRetry: ACErrorRetryCompletion)
    func upload(task: ACUploadTaskProtocol, responseOnMainQueue: Bool, success: ACResponse?, failRetry: ACErrorRetryCompletion)
}
