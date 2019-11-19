//
//  Layer.swift
//  Force
//
//  Created by Conrad Kramer on 10/3/16.
//  Copyright © 2016 Conrad Kramer. All rights reserved.
//

import UIKit

public struct ViewParticle: Particle, Equatable, Hashable {
    public var velocity: CGPoint
    public var position: CGPoint
    public var fixed: Bool
    fileprivate let view: Unmanaged<UIView>
    
    /// 数据模型
    public var model: Any? = nil
    
//    public var hashValue: Int {
//        return view.takeUnretainedValue().hashValue
//    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(view.takeUnretainedValue().hashValue)
//        hasher.combine(self.view.takeRetainedValue())
    }
    
    public init(view: UIView) {
        self.view = .passUnretained(view)
        self.velocity = .zero
        self.position = view.center
        self.fixed = false
    }
    
    @inline(__always)
    public func tick() {
        view.takeUnretainedValue().center = position
    }
}

public func ==(lhs: ViewParticle, rhs: ViewParticle) -> Bool {
    return lhs.view.toOpaque() == rhs.view.toOpaque()
}
