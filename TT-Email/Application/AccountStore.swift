//
//  APPStore.swift
//  TT-Email
//
//  Created by tanson on 16/4/29.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import YTKKeyValueStore

private let ACCOUNTSTORE = "accountStore_DB"
private let ACCOUNTTABLE = "account_table"

class AccountStore{
    
    //账号管理
    var accountStore:YTKKeyValueStore = {
        let store = YTKKeyValueStore(DBWithName: ACCOUNTSTORE)
        store.createTableWithName(ACCOUNTTABLE)
        return store
    }()
    
    func addAccount(account:Account){
        let accountDic = account.toDictionry()
        self.accountStore.putObject(accountDic, withId: account.username, intoTable: ACCOUNTTABLE)
    }
    
    var allAccount:Array<Account> {
        var allAccount = [Account]()
        let allItem = self.accountStore.getAllItemsFromTable(ACCOUNTTABLE)
        for item in allItem{
            let emailAccount = Account.fromDictionry( item.itemObject as! NSDictionary )
            allAccount.append(emailAccount)
        }
        return allAccount
    }
    
    func getAccountForName(name:String)->Account?{
        for account in self.allAccount{
            if account.username == name{
                return account
            }
        }
        return nil
    }
}


