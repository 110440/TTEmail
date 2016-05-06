//
//  App.swift
//  TT-Email
//
//  Created by tanson on 16/4/25.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

private let CUR_LOGIN_USER_NAME = "curLoginUserName"

let APP = App()

class App {
    
    //账号管理
    var accountStore:AccountStore = {
        let store = AccountStore()
        return store
    }()
    
    func setCurLoginUserName(name:String){
        NSUserDefaults.standardUserDefaults().setObject(name, forKey: CUR_LOGIN_USER_NAME)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func getCurLoginUserName()->String?{
        let name = NSUserDefaults.standardUserDefaults().objectForKey(CUR_LOGIN_USER_NAME) as? String
        return name
    }

    var curFoldername = "INBOX"
    var curAccount:Account?

    var messageStore:MessageStore  = {
        let store = MessageStore()
        return store
    }()
    
    init() {
        
        if let userName = self.getCurLoginUserName(),let curAccount = self.accountStore.getAccountForName(userName) {
            self.curAccount = curAccount
        }
    }
}