//
//  Table.swift
//  TT-Email
//
//  Created by tanson on 16/4/29.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation


class Table {
    let stroe:YTKKeyValueStore
    let name:String
    init(store:YTKKeyValueStore,name:String){
        self.stroe = store
        self.name = name
        store.createTableWithName(name)
    }
    
    func putObject(object:AnyObject,key:String){
        self.stroe.putObject(object, withId: key, intoTable: self.name)
    }
    
    func objectForKey(key:String)->AnyObject?{
        let object = self.stroe.getObjectById(key, fromTable: self.name)
        return object
    }
    
    func putString(string:String,key:String){
        self.stroe.putString(string, withId: key, intoTable: self.name)
    }
    
    func stringForKey(key:String)->String?{
        let str = self.stroe.getStringById(key, fromTable: self.name)
        return str
    }
    
    func allObject() -> [AnyObject] {
        var allObject = [AnyObject]()
        let all = self.stroe.getAllItemsFromTable(self.name)
        for item in all{
            allObject.append(item.itemObject)
        }
        return allObject
    }
    
    func clearTable(){
        self.stroe.clearTable(self.name)
    }
    
    func deleteBy(key:String){
        self.stroe.deleteObjectById(key, fromTable: self.name)
    }
}