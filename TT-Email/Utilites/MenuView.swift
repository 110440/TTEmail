//
//  MenuView.swift
//  ScreenEdgePanGesture
//
//  Created by tanson on 16/5/4.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

private let viewAlpha:CGFloat = 0.7
private let screentSize = UIScreen.mainScreen().bounds.size


class MenuView: UIView ,UITableViewDataSource ,UITableViewDelegate{

    var menuWidth:CGFloat = 0
    var startX:CGFloat = 0
    
    lazy var backView:UIView = {
        let view = UIView(frame: self.bounds)
        view.alpha = 0
        view.backgroundColor = UIColor.blackColor()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tap(_:)))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
        return view
    }()
    
    lazy var tableView:UITableView = {
        let h = self.bounds.height
        let tableViewRect = CGRect(x: -self.menuWidth, y: 0, width: self.menuWidth, height: h)
        let view = UITableView(frame: tableViewRect, style: .Grouped)
        view.dataSource = self
        view.delegate = self
        view.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return view
    }()
    
    init(w:CGFloat,h:CGFloat){
        
        self.menuWidth = w
        let rect = UIScreen.mainScreen().bounds
        super.init(frame: rect)
        
        self.userInteractionEnabled = false

        self.addSubview(self.backView)
        self.addSubview(self.tableView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
        self.addGestureRecognizer(pan)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    weak var delegate:MenuViewDeleaget? {
        didSet{
            let screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.edgePan(_:)))
            screenEdgeRecognizer.edges = .Left
            if let target = delegate as? UIViewController{
                target.view.addGestureRecognizer(screenEdgeRecognizer)
            }else if let target = delegate as? UIView{
                target.addGestureRecognizer(screenEdgeRecognizer)
            }
        }
    }
    
    func showMenu(speed:CGFloat = 600){
        
        let d = Double(abs(self.tableView.frame.minX) / speed)
        UIView.animateWithDuration(d, animations: {
            self.tableView.frame.origin.x = 0
            self.backView.alpha = viewAlpha
            self.tabBar?.alpha = 0
            self.tabBar?.frame.origin.y = screentSize.height
        }){ end in
            self.userInteractionEnabled = true
        }
    }
    
    func hideMenu(speed:CGFloat = 800){
        
        let d = Double(abs(self.tableView.frame.maxX) / speed)
        UIView.animateWithDuration(d, animations: {
            self.tableView.frame.origin.x = -self.menuWidth
            self.backView.alpha = 0
            
            if let tabBar = self.tabBar{
                tabBar.alpha = 1
                tabBar.frame.origin.y = screentSize.height - tabBar.frame.height
            }
        }){ end in
            self.userInteractionEnabled = false
        }
    }
    
    private var tabBar:UITabBar?{
        let vc = self.delegate as? UIViewController
        return vc?.tabBarController?.tabBar
    }
    
    func reloadData(){
        self.tableView.reloadData()
    }
    
    // 按百分比显示tabBar
    private func showTabBarByPercentage(p:CGFloat){
        if let tabBar = self.tabBar {
            let barHeight = tabBar.frame.height
            let y = screentSize.height - (barHeight * (1-p))
            tabBar.frame.origin.y = y
            tabBar.alpha = 1 - p * viewAlpha
        }
    }
    
    //MARK: GestureRecognizer action
    
    func tap(sender:UITapGestureRecognizer){
        if sender.state == .Ended{
            self.hideMenu()
        }
    }
    
    func pan(sender:UIPanGestureRecognizer){
        
        let state = sender.state
        if state == .Began{
            self.startX = sender.locationInView(self).x
            
        }else if state == .Changed{
            let location = sender.locationInView(self)
            let dx = location.x - self.startX
            self.startX = location.x
            
            // x (-self.menuWidth ~ 0 )
            var x = self.tableView.frame.origin.x + dx
            x = min(0, x)
            x = max(x, -self.menuWidth)
            self.tableView.frame.origin.x = x
            
            //完成百分比
            let p = abs(self.menuWidth + x) / self.menuWidth
            self.backView.alpha = p * viewAlpha
            
            //move tabBar
            self.showTabBarByPercentage(p)
            
            self.delegate?.MenuViewShowPercentage?(Float(p))

        }else if state == .Cancelled || state == .Ended {
            let v = sender.velocityInView(self.backView)
            if v.x <= -300 {
                self.hideMenu(abs(v.x))
            }else if self.tableView.frame.minX < -self.menuWidth/2 {
                self.hideMenu()
            }else{
                self.showMenu()
            }
        }
    }
    
    
    func edgePan(sender: UIScreenEdgePanGestureRecognizer){
        if sender.state == .Began || sender.state == .Changed{
            let location = sender.locationInView(self.superview)

            // x (-self.menuWidth ~ 0 )
            var x = -self.menuWidth + location.x
            x = min(0, x)
            x = max(x, -self.menuWidth)
            self.tableView.frame.origin.x = x
            
            //完成百分比
            let p = (self.menuWidth + x)/self.menuWidth
            self.backView.alpha = p * viewAlpha
            
            self.showTabBarByPercentage(p)
            
            self.delegate?.MenuViewShowPercentage?(Float(p))
            
        }else if sender.state == .Cancelled || sender.state == .Ended{
            let location = sender.locationInView(self.superview)
            let v = sender.velocityInView(self.superview)
            if v.x > 300 {
                self.showMenu(v.x)
            }else if location.x >= self.menuWidth/2{
                self.showMenu()
            }else{
                self.hideMenu()
            }
        }
    }
    
    //MARK:- tableView delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.delegate?.numberOfSectionsForMenuView(self) ?? 0
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.delegate?.numberOfRowsInSectionForMenuView(self, section: section) ?? 0
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell",forIndexPath: indexPath)
        self.delegate?.menuView(self, willShowCell: cell, indexPath: indexPath)
        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.delegate?.menuView?(self, titleForHeaderInSection: section) ?? ""
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        if section == 0{
            return 0.1
        }
        return 30
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat{
        return 10
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.hideMenu()
        self.delegate?.menuView?(self, selectRowAtIndexPath: indexPath)
    }
}

//MARK:- Menuview protocol
@objc protocol MenuViewDeleaget:NSObjectProtocol {
    optional func MenuViewShowPercentage(p:Float)
    func numberOfSectionsForMenuView(view:MenuView)->Int
    func numberOfRowsInSectionForMenuView(view:MenuView ,section: Int)->Int
    func menuView(view:MenuView,willShowCell cell:UITableViewCell,indexPath:NSIndexPath)->Void
    optional func menuView(view:MenuView , titleForHeaderInSection section: Int)->String?
    optional func menuView(view:MenuView, selectRowAtIndexPath indexPath:NSIndexPath)->Void
}
