//
//  ViewController.swift
//  TT-Email
//
//  Created by tanson on 16/4/25.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit


class MainViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        
        let email = EmailViewController(nibName: "EmailViewController", bundle: nil)
        email.title = "邮件"
        email.tabBarItem.image = UIImage(named: "envelope")
        let vc1 = UINavigationController(rootViewController: email)
        
        let todo = TodoViewController(nibName: "TodoViewController", bundle: nil)
        todo.title = "待办"
        todo.tabBarItem.image = UIImage(named: "time")
        let vc2 = UINavigationController(rootViewController: todo)
        
        let friends = FriendsViewController(nibName: "FriendsViewController", bundle: nil)
        friends.title = "通信录"
        friends.tabBarItem.image = UIImage(named: "book")
        let vc3 = UINavigationController(rootViewController: friends)
        
        let me = MeViewController(nibName: "MeViewController", bundle: nil)
        me.title = "我"
        me.tabBarItem.image = UIImage(named: "profile")
        let vc4 = UINavigationController(rootViewController: me)
        
        self.viewControllers = [vc1,vc2,vc3,vc4]
    }
    
}

