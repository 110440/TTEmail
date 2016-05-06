//
//  Folder.swift
//  TT-Email
//
//  Created by tanson on 16/5/3.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

struct Folder {
    let name:String
    var count:UInt64
    
    static func fromDictionry(dic:NSDictionary)->Folder{
        let name = dic["name"] as! String
        let count = (dic["count"] as? NSNumber)?.unsignedLongLongValue ?? 0
        return Folder(name: name , count: count)
    }
    
    func toDictionry()->NSMutableDictionary{
        let dic = NSMutableDictionary()
        dic["name"] = self.name
        dic["count"] = NSNumber(unsignedLongLong: self.count)
        return dic
    }
}