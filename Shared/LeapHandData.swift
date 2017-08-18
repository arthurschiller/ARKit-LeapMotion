//
//  LeapData.swift
//  Mac App
//
//  Created by Arthur Schiller on 18.08.17.
//

import Foundation
import CoreGraphics

struct CodableVector: Codable {
    let x: CGFloat
    let y: CGFloat
    let z: CGFloat
}

struct LeapHandData: Codable {
//    let palmPos: CodableVector
    let palmRot: CodableVector
}

struct LeapPointableData: Codable {
    let pointablePos: CodableVector
}
