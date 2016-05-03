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
    var offset:UInt64
    
    static func fromDictionry(dic:NSDictionary)->Folder{
        let name = dic["name"] as! String
        return Folder(name: name, offset: 0)
    }
    
    func toDictionry()->NSMutableDictionary{
        let dic = NSMutableDictionary()
        dic["name"] = self.name
        return dic
    }
}