//
//  ViewController.swift
//  JZForceView
//
//  Created by wizet on 2019/11/19.
//  Copyright © 2019 wizet. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
           view.backgroundColor = .white
           
           
           let forceView = JZForceView()
           forceView.translatesAutoresizingMaskIntoConstraints = false
           self.view.addSubview(forceView)
           forceView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
           forceView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
           forceView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
           forceView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
           
           
           if let path = Bundle.main.path(forResource: "ExaItems", ofType: "plist")
               , let dic = NSDictionary.init(contentsOfFile: path)
           {
               forceView.update(data: self.nodes(value: dic as! Dictionary<String, Any>))
               forceView.start()
           }
       }
       
       
       func nodes(value: Dictionary<String, Any>) -> ExaItem {
           let tnm = ExaItem()
           let wh = arc4random_uniform(20) + 30
           tnm.size = .init(width: CGFloat(wh), height: CGFloat(wh))
           tnm.title = value["name"] as! String
           tnm.color = UIColor.init(red: CGFloat(arc4random_uniform(255)) / 255.0, green: CGFloat(arc4random_uniform(255)) / 255.0, blue: CGFloat(arc4random_uniform(255)) / 255.0, alpha: 1.0)
           if let arr = value["children"] as? [Dictionary<String, Any>] {
               for element in arr {
                   tnm.children.append(self.nodes(value: element))
               }
           }
           return tnm
       }

}




class ExaItem: UIView, JZForceViewItemProtocol {
    
    var color = UIColor.white
    var title = "--"
    var size = CGSize.zero
    var children: [ExaItem] = []
    
    //MARK: JZForceViewItemProtocol
    func itemColor() -> UIColor {
        return color
    }
    func itemSize() -> CGSize {
        return size
    }
    func itemTitle() -> String {
        return title
    }
    func itemChildren() -> [JZForceViewItemProtocol] {
        return children
    }
    func itemData() -> Any? {
        return nil
    }
    func itemClickedAction(itemData: Any?) {
        if let itemData = itemData {
            print(itemData)
        }
    }
}
