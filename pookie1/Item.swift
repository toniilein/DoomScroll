//
//  Item.swift
//  pookie1
//
//  Created by Antonio Bartulovic on 26.02.26.
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
