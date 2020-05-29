//
//  ACError.swift
//  AlamoClient
//
//  Created by CavanSu on 2020/5/25.
//  Copyright © 2020 CavanSu. All rights reserved.
//

public struct ACError: Error {
    public enum ErrorType {
        case fail(String)
        case invalidParameter(String)
        case valueNil(String)
        case convert(String, String)
        case unknown
    }
    
    public var localizedDescription: String {
        switch type {
        case .fail(let reason):             return "\(reason)"
        case .invalidParameter(let para):   return "\(para)"
        case .valueNil(let para):           return "\(para) nil"
        case .convert(let a, let b):        return "\(a) converted to \(b) error"
        case .unknown:                      return "unknown error"
        }
    }
    
    public var type: ErrorType
    public var code: Int?
    public var extra: String?
    
    public static func fail(_ text: String, code: Int? = nil, extra: String? = nil) -> ACError {
        return ACError(type: .fail(text), code: code, extra: extra)
    }
    
    public static func invalidParameter(_ text: String, code: Int? = nil, extra: String? = nil) -> ACError {
        return ACError(type: .invalidParameter(text), code: code, extra: extra)
    }
    
    public static func valueNil(_ text: String, code: Int? = nil, extra: String? = nil) -> ACError {
        return ACError(type: .valueNil(text), code: code, extra: extra)
    }
    
    public static func convert(_ from: String, _ to: String) -> ACError {
        return ACError(type: .convert(from, to))
    }
    
    public static func unknown() -> ACError {
        return ACError(type: .unknown)
    }
}
