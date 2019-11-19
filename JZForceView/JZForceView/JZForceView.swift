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
}


/// 改自： https://github.com/conradev/Force
/// https://observablehq.com/@d3/force-directed-tree
class JZForceView: UIView {
    private var scrollView: UIScrollView = UIScrollView()
    
    private let VPcenter: Center<ViewParticle> = Center(.zero)
    
    private let manyParticle: ManyParticle<ViewParticle> = ManyParticle()
    
    private let links: Links<ViewParticle> = Links()
    private lazy var linkLayer: CAShapeLayer = {
        let linkLayer = CAShapeLayer()
        linkLayer.strokeColor = UIColor.gray.cgColor
        linkLayer.fillColor = UIColor.clear.cgColor
        linkLayer.lineWidth = 2
        self.scrollView.layer.insertSublayer(linkLayer, at: 0)
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
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        linkLayer.frame = self.bounds
    }
    
    
    ///通过模型修改当前的数据
    func update(data: JZForceViewItemProtocol) {
        
        let subViews = scrollView.subviews
        for element in subViews {
            element.removeFromSuperview()
        }
        
        let root = self.particle(data: data)
        self.buildRelationship(data: data, parent: root)
        
        
        var minY: CGFloat? = nil
        var minX: CGFloat? = nil
        var maxY: CGFloat? = nil
        var maxX: CGFloat? = nil
        
        // 修正contentSize以及offset
        simulation.calPositions()
        for element in simulation.particles {
            if let tmp = minY {
                if tmp > element.position.y {
                    minY = element.position.y
                }
            } else {
                minY = element.position.y
            }
            
            if let tmp = minX {
                if tmp > element.position.x {
                    minX = element.position.x
                }
            } else {
                minX = element.position.x
            }
            
            if let tmp = maxY {
                if tmp < element.position.y {
                    maxY = element.position.y
                }
            } else {
                maxY = element.position.y
            }
            
            if let tmp = maxX {
                if tmp < element.position.x {
                    maxX = element.position.x
                }
            } else {
                maxX = element.position.x
            }
        }
        if let minY = minY, let maxY = maxY, let minX = minX, let maxX = maxX {
            let cX = max((maxX - minX) , self.bounds.midX)
            let cY = max((maxY - minY) , self.bounds.midY)
            //FIXME: 这个是写了一个比较大的范围，并非是精确的
            let c = max(cX, cY) + 30.0;
            VPcenter.center = CGPoint(x: c, y: c)
            self.scrollView.contentSize = .init(width: c * 2, height: c * 2)
            let offset: CGPoint = .init(x: max(VPcenter.center.x - (self.bounds.width / 2.0), 0), y: max(VPcenter.center.y - (self.bounds.height / 2.0), 0))
            self.scrollView.setContentOffset(offset, animated: false)
        } else {
            VPcenter.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            self.scrollView.contentSize = self.bounds.size
        }
    }
    
    private func buildRelationship(data: JZForceViewItemProtocol, parent: ViewParticle) {
        let distance: CGFloat = {
            if data.itemChildren().count  < 5 {
                return 60
            } else if data.itemChildren().count < 10 {
                return 80
            } else {
                return 100
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
        view.center = CGPoint(x: CGFloat(arc4random_uniform(320)), y: -CGFloat(arc4random_uniform(100)))
        let wh = data.itemSize()
        
        let inset: CGFloat = 15.0
        view.bounds = CGRect(x: 0, y: 0, width: wh.width + inset * 2, height: wh.height + inset * 2)
        self.scrollView.addSubview(view)
        
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
            //FIXME: 存在优化空间，可优化滑动效果
            particle.position = gestureRecognizer.location(in: self.scrollView)
            simulation.kick()
        case .cancelled, .ended:
            particle.fixed = false
            particle.velocity += gestureRecognizer.velocity(in: self.scrollView) * 0.05
        default:
            break
        }
        simulation.particles.update(with: particle)
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
