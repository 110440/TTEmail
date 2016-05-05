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

    
    //////
    
    func loginForIMAP(account:EmailAccount, completion:(error:NSError?)->Void){
        
        if self.curIMAPSession != nil && self.curEmailAccount?.username == account.username {
            completion(error: nil)
            return
        }
        IMAPSession.sessionWithLogin(account.IMAPHotname, port:account.IMAPPort, username: account.username, password: account.password) { (error, session, folders) in
            if let e = error{
                completion(error: e)
            }else{
                self.curIMAPSession = session
                self.curEmailAccount = account
                self.curEmailAccount?.folders = folders
                self.curFoldername = "INBOX"
                self.accountStore.addAccount(self.curEmailAccount!)
            
                completion(error: nil)
            }
        }
    }
    
    
    func updateFolderForCurAccount(folder:Folder){
        
    }
    
    var curEmailAccount:EmailAccount?
    var curIMAPSession:IMAPSession?
    var curFoldername = "INBOX"
    
    var emailStore:EmailStore = {
        let store = EmailStore()
        return store
    }()
    
    init() {
        
        
    }
}