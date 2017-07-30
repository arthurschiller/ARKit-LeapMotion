//
//  LeapMotionGestureService.swift
//  Mac App
//
//  Created by Arthur Schiller on 28.07.17.
//

import CoreBluetooth

enum LeapMotionGestureService {
    static let uuid: CBUUID = CBUUID(string: "B7AC06DC-09FF-40ED-B03A-55D09B08EB4A")
    static let testStringUUID: CBUUID = CBUUID(string: "B7AC06DC-09FF-40ED-B03A-55D09B080001")
    
    static let characteristics: [CBUUID] = [
        testStringUUID,
    ]
}
