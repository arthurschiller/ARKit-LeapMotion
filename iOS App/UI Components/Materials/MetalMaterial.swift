//
//  MetalMaterial.swift
//  iOS App
//
//  Created by Arthur Schiller on 20.08.17.
//

import Foundation
import SceneKit

class MetalMaterial: SCNMaterial {
    
    enum SurfaceType {
        case streaked
        case greasy
    }
    
    var surfaceType: SurfaceType = .streaked
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    init(surfaceType: SurfaceType) {
        super.init()
        self.surfaceType = surfaceType
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        lightingModel = SCNMaterial.LightingModel.physicallyBased
        set(surfaceType: surfaceType)
    }
    
    private func set(surfaceType: SurfaceType) {
        switch surfaceType {
        case .streaked:
            diffuse.contents = UIImage(named: "streakedMetal-albedo")
            roughness.contents = UIImage(named: "streakedMetal-roughness")
            metalness.contents = UIImage(named: "streakedMetal-metalness")
        case .greasy:
            diffuse.contents = UIImage(named: "greasyMetal-albedo")
            roughness.contents = UIImage(named: "greasyMetal-roughness")
            metalness.contents = UIImage(named: "greasyMetal-metalness")
            normal.contents = UIImage(named: "greasyMetal-normal")
        }
    }
}
