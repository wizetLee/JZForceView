//
//  JZForceView.swift
//  Demo
//
//  Created by wizet on 2019/11/18.
//  Copyright © 2019 Conrad Kramer. All rights reserved.
//

import UIKit

protocol JZForceViewItemProtocol {
    func itemColor() -> UIColor
    func itemSize() -> CGSize
    func itemTitle() -> String
    func itemChildren() -> [JZForceViewItemProtocol]
    func itemData() -> Any?
    func itemClickedAction(itemData: Any?)
    func itemDepth() -> Int
}

/// 改自： https://github.com/conradev/Force
/// https://observablehq.com/@d3/force-directed-tree
class JZForceView: UIView {
    private var scrollView: JZForceViewScrollView = JZForceViewScrollView()
    
    private var contentView: UIView = UIView()
    
    private let VPcenter: Center<ViewParticle> = Center(.zero)
    
    private let manyParticle: ManyParticle<ViewParticle> = ManyParticle()
    
    private let links: Links<ViewParticle> = Links()
    
    private var rootData: JZForceViewItemProtocol? = nil
    
    private var pinchGesture: UIPinchGestureRecognizer? = nil
    
    private lazy var linkLayer: CAShapeLayer = {
        let linkLayer = CAShapeLayer()
        linkLayer.strokeColor = UIColor.gray.cgColor
        linkLayer.fillColor = UIColor.clear.cgColor
        linkLayer.lineWidth = 2
        self.contentView.layer.insertSublayer(linkLayer, at: 0)
        return linkLayer
    }()
    
    fileprivate lazy var simulation: Simulation<ViewParticle> = {
        let simulation: Simulation<ViewParticle>  = Simulation()
        simulation.insert(force: self.manyParticle)
        simulation.insert(force: self.links)
        simulation.insert(force: self.VPcenter)
        simulation.insert(tick: { self.linkLayer.path = self.links.path(from: &$0) })
        return simulation
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.scrollView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.scrollView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.contentView.backgroundColor = .clear
        self.scrollView.addSubview(self.contentView)
        
        self.pinchEnable(enable: true)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        linkLayer.frame = self.bounds
        self.contentView.frame = self.bounds
        
        
        // 设置滑动范围
        if let root = rootData {
            let width = CGFloat(root.itemDepth()) * 150 * 2.0 + CGFloat(root.itemDepth() - 1 >= 0 ? root.itemDepth() - 1 : 0) * 50
            VPcenter.center = CGPoint(x: width / 2.0, y: width / 2.0)
            self.scrollView.contentSize = .init(width: width, height: width)
            self.contentView.frame = .init(x: 0.0, y: 0.0, width: self.scrollView.contentSize.width, height: self.scrollView.contentSize.height)
            let offset: CGPoint = .init(x: max(VPcenter.center.x - (self.bounds.width / 2.0), 0), y: max(VPcenter.center.y - (self.bounds.height / 2.0), 0))
            self.scrollView.setContentOffset(offset, animated: false)
        }
    }
    
    private var minimumPinchScale: CGFloat = 0.3
    private var pinchScale: CGFloat = 0.0
    private var lastPinchScale: CGFloat = 0.0
    @objc private func pinchAction(sender: UIPinchGestureRecognizer) {
        if lastPinchScale > 0 {
            if lastPinchScale - sender.scale > 0 {
                pinchScale -= 0.0075
            } else {
                pinchScale += 0.0075
            }
            
            if pinchScale <= -0.5 {
                pinchScale = -0.5
            } else if pinchScale >= 1.0 {
                pinchScale = 1.0
            }
        }
        
        lastPinchScale = sender.scale
        if minimumPinchScale <= pinchScale {
            pinchScale = minimumPinchScale
        }
        
        if (sender.state == UIGestureRecognizer.State.ended
            || sender.state == UIGestureRecognizer.State.failed
            || sender.state == UIGestureRecognizer.State.cancelled) {
            lastPinchScale = 0
        }
        
        self.contentView.transform = CGAffineTransform.init(scaleX: 1 + pinchScale, y: 1 + pinchScale)
    }
    
    
    private func buildRelationship(data: JZForceViewItemProtocol, parent: ViewParticle) {
        let distance: CGFloat = {
            if data.itemChildren().count  < 5 {
                return 100
            } else if data.itemChildren().count < 10 {
                return 120
            } else {
                return 150.0
            }
        }()
        for element in data.itemChildren() {
            let sub_vp = self.particle(data: element)
            links.link(between: parent, and: sub_vp, strength: nil, distance: distance)
            self.buildRelationship(data: element, parent: sub_vp)
        }
    }
    
    private func particle(data: JZForceViewItemProtocol) -> ViewParticle {
        let view = JZForceItemView()
//        view.center = CGPoint(x: CGFloat(arc4random_uniform(320)), y: -CGFloat(arc4random_uniform(100)))
        // 隐藏初始的位置
        view.center = .init(x: -200, y: -200)
        let wh = data.itemSize()
        
        let inset: CGFloat = 15.0
        view.bounds = CGRect(x: 0, y: 0, width: wh.width + inset * 2, height: wh.height + inset * 2)
        self.contentView.addSubview(view)
        
        let gestureRecogizer = UIPanGestureRecognizer(target: self, action: #selector(dragged(_:)))
        view.addGestureRecognizer(gestureRecogizer)
        
        let layer = CAShapeLayer()
        layer.frame = view.bounds
        layer.path = UIBezierPath(ovalIn: CGRect(x: inset, y: inset, width: wh.width, height: wh.height)).cgPath
        layer.fillColor = data.itemColor().cgColor
        view.layer.addSublayer(layer)
        view.titleLabel.text = data.itemTitle()
        
        
        let particle = ViewParticle(view: view)
        simulation.insert(particle: particle)
        return particle
    }
    
    
    public func start() {
        simulation.start()
    }
    
    public func stop() {
        simulation.stop()
    }
    
    @objc private func dragged(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let view = gestureRecognizer.view, let index = simulation.particles.firstIndex(of: ViewParticle(view: view)) else { return }
        var particle = simulation.particles[index]
        
        
        switch gestureRecognizer.state {
        case .began:
            particle.fixed = true
        case .changed:
            var point = gestureRecognizer.translation(in: self)
            if let viewCenter = gestureRecognizer.view?.center {
                point.x = point.x + viewCenter.x
                point.y = point.y + viewCenter.y
            }
            particle.position = point
            //            particle.position = gestureRecognizer.location(in: self.contentView)
            simulation.kick()
            
            gestureRecognizer.setTranslation(.zero, in: self.contentView);
        case .cancelled, .ended, .failed:
            particle.fixed = false
            particle.velocity += gestureRecognizer.velocity(in: self.contentView) * 0.05
        default:
            break
        }
        simulation.particles.update(with: particle)
    }
    
    

     //MARK: public
     ///通过模型修改当前的数据
     public func update(data: JZForceViewItemProtocol) {
         self.rootData = data
         
         let subViews = contentView.subviews
         for element in subViews {
             element.removeFromSuperview()
         }
         
         let root = self.particle(data: data)
         self.buildRelationship(data: data, parent: root)
         
     }
     
    public func pinchEnable(enable: Bool) {
         if pinchGesture == nil {
             
             pinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(pinchAction(sender:)))
             self.contentView.addGestureRecognizer(pinchGesture!)
         }
         pinchGesture?.isEnabled = enable
     }
}


class JZForceViewScrollView: UIScrollView {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.jz_gestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer)
    }
    
    func jz_gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.state == .began || otherGestureRecognizer.state == .possible {
            if let classForCoder = otherGestureRecognizer.view?.classForCoder
                , "UILayoutContainerView" == "\(classForCoder)" {
                self.panGestureRecognizer.require(toFail: otherGestureRecognizer)
                return true
            }
        }
        return false
    }
}



class JZForceItemView: UIView {
    var titleLabel: UILabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.titleLabel)
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.titleLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.titleLabel.adjustsFontSizeToFitWidth = true
        self.titleLabel.font = .systemFont(ofSize: 11.0)
        self.titleLabel.textAlignment = .center
        self.titleLabel.layer.zPosition = 1
        self.titleLabel.text = "--"
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}


extension UIColor {
    fileprivate convenience init(rgbaValue: UInt32) {
        let max = CGFloat(UInt8.max)
        self.init(red: CGFloat((rgbaValue >> 24) & 0xFF) / max,
                  green: CGFloat((rgbaValue >> 16) & 0xFF) / max,
                  blue: CGFloat((rgbaValue >> 8) & 0xFF) / max,
                  alpha: CGFloat(rgbaValue & 0xFF) / max)
    }
}
