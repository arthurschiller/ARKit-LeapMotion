//
//  SharedExtensions.swift
//  Mac App
//
//  Created by Arthur Schiller on 08.08.17.
//

import Foundation

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
