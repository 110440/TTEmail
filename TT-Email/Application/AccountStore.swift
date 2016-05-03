//
//  APPStore.swift
//  TT-Email
//
//  Created by tanson on 16/4/29.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

private let ACCOUNTSTORE = "accountStore_DB"
private let ACCOUNTTABLE = "account_table"

class AccountStore{
    
    //账号管理
    var accountStore:YTKKeyValueStore = {
        let store = YTKKeyValueStore(DBWithName: ACCOUNTSTORE)
        store.createTableWithName(ACCOUNTTABLE)
        return store
    }()
    
    func addAccount(account:EmailAccount){
        let accountDic = account.toDictionry()
        self.accountStore.putObject(accountDic, withId: account.username, intoTable: ACCOUNTTABLE)
    }
    
    var allAccount:Array<EmailAccount> {
        var allAccount = [EmailAccount]()
        let allItem = self.accountStore.getAllItemsFromTable(ACCOUNTTABLE)
        for item in allItem{
            let emailAccount = EmailAccount.fromDictionry( item.itemObject as! NSDictionary )
            allAccount.append(emailAccount)
        }
        return allAccount
    }
    
    func getAccountForName(name:String)->EmailAccount?{
        for account in self.allAccount{
            if account.username == name{
                return account
            }
        }
        return nil
    }
}


