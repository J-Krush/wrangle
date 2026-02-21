//
//  Item.swift
//  corral
//
//  Created by John Kreisher on 2/21/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
