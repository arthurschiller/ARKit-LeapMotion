//
//  LeapMotionGestureService.swift
//  Mac App
//
//  Created by Arthur Schiller on 28.07.17.
//

import CoreBluetooth

enum LeapMotionGestureService {
    static let uuid: CBUUID = CBUUID(string: "54A9FEA5-E8F5-4D50-A4AA-759FCC0F0821")
    static let leapHandData: CBUUID = CBUUID(string: "54A9FEA5-E8F5-4D50-A4AA-759FCC000001")
    
    static let characteristics: [CBUUID] = [
        leapHandData
    ]
}
