//
//  ACUtils.swift
//  AlamoClient
//
//  Created by CavanSu on 2020/5/25.
//  Copyright © 2020 CavanSu. All rights reserved.
//

struct OptionsDescription {
    static func any<any>(_ any: any?) -> String where any: CustomStringConvertible {
        return any != nil ? any!.description : "nil"
    }
}

class AfterWorker {
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    func perform(after: TimeInterval, on queue: DispatchQueue, _ block: @escaping (() -> Void)) {
        // Cancel the currently pending item
        pendingRequestWorkItem?.cancel()
        
        // Wrap our request in a work item
        let requestWorkItem = DispatchWorkItem(block: block)
        pendingRequestWorkItem = requestWorkItem
        queue.asyncAfter(deadline: .now() + after, execute: requestWorkItem)
    }
    
    func cancel() {
        pendingRequestWorkItem?.cancel()
    }
}
