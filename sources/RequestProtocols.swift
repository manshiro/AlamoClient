//
//  RequestProtocols.swift
//  RequestProtocols
//
//  Created by CavanSu on 2019/6/19.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation

protocol AGERequestEvent: AGEDescription {
    var name: String {get set}
}

protocol AGERequestTaskProtocol {
    var id: Int {get set}
    var event: AGERequestEvent {get set}
    var requestType: RequestType {get set}
    var timeout: RequestTimeout {get set}
    var header: [String: String]? {get set}
    var parameters: [String: Any]? {get set}
}

protocol AGEUploadTaskProtocol: AGERequestTaskProtocol {
    var object: UploadObject {get set}
}

// MARK: - Request APIs
protocol RequestClientProtocol {
    func request(task: AGERequestTaskProtocol, responseOnMainQueue: Bool, success: AGEResponse?, failRetry: ErrorRetryCompletion)
    func upload(task: AGEUploadTaskProtocol, responseOnMainQueue: Bool, success: AGEResponse?, failRetry: ErrorRetryCompletion)
}
