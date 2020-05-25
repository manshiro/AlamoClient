//
//  NetworkMonitor.swift
//  NetworkMonitor
//
//  Created by CavanSu on 2019/7/11.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation
import Alamofire

enum AGENetConnection: AGEDescription {
    case unknown, notReachable, ethernetOrWiFi, wwan
    
    var description: String {
        return cusDescription()
    }
    
    var debugDescription: String  {
        return cusDescription()
    }
    
    func cusDescription() -> String {
        switch self {
        case .unknown:          return "unknown"
        case .notReachable:     return "notReachable"
        case .ethernetOrWiFi:   return "ethernetOrWiFi"
        case .wwan:             return "wwan"
        }
    }
}

enum AGENetQuality: AGEDescription {
    case unknown, excellent, good, poor, bad, verybad, down
    
    var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    func cusDescription() -> String {
        switch self {
        case .unknown:      return "unknown"
        case .excellent:    return "excellent"
        case .good:         return "good"
        case .poor:         return "poor"
        case .bad:          return "bad"
        case .verybad:      return "verybad"
        case .down:         return "down"
        }
    }
}

protocol NetworkMonitorDelegate: NSObjectProtocol {
    func networkMonitorDidConnectionChanged(connection: AGENetConnection)
    func networkMonitorDidQualityChanged(quality: AGENetQuality)
}

class NetworkMonitor: NSObject, AGELogBase {
    private lazy var netListener = NetworkReachabilityManager(host: "www.apple.com")

    weak var delegate: NetworkMonitorDelegate?

    var logTube: LogTube
    
    var connect: AGENetConnection = .unknown {
        didSet {
            if oldValue == connect {
                return
            }
            log(info: "net connect changed: \(connect.description)")
            delegate?.networkMonitorDidConnectionChanged(connection: connect)
        }
    }

    var quality: AGENetQuality = .unknown {
        didSet {
            if oldValue == quality {
                return
            }
            log(info: "net quality changed: \(quality.description)")
            delegate?.networkMonitorDidQualityChanged(quality: quality)
        }
    }

    init(logTube: LogTube) {
        self.logTube = logTube
    }
}

extension NetworkReachabilityManager.NetworkReachabilityStatus {
    var AGE: AGENetConnection {
        switch self {
        case .reachable(let type):  return ((type == .ethernetOrWiFi ? .ethernetOrWiFi : .wwan))
        case .notReachable:         return .notReachable
        case .unknown:              return .unknown
        }
    }
}

extension NetworkMonitor {
    func action(_ action: AGESwitch) {
        guard let netListener = self.netListener else {
            log(error: AGEError.valueNil("netListener"))
            return
        }

        switch action {
        case .on:
            netListener.listener = { [unowned self] status in
                self.connect = status.AGE
            }
            netListener.startListening()
            log(info: "start monitor")
        case .off:
            netListener.stopListening()
            log(info: "stop monitor")
        }
    }
}

private extension NetworkMonitor {
    func log(info: String, funcName: String = #function, extra: String? = nil) {
        let className = NetworkMonitor.self
        logOutputInfo(info, extra: extra, className: className, funcName: funcName)
    }

    func log(error: Error, funcName: String = #function, extra: String? = nil) {
        let className = NetworkMonitor.self
        logOutputError(error, extra: extra, className: className, funcName: funcName)
    }
}
