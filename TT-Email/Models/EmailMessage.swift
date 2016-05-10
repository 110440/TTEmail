//
//  EmailMessage.swift
//  TT-Email
//
//  Created by tanson on 16/4/28.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

class EmailMessage {
    
    let uid:UInt32
    let subject:String
    let displayName:String
    //var summaryText:String?
    //var htmlBody:String?
    var time:Double
    var readed:Int = 0
    
    init(uid:UInt32, subject:String,displayName:String,time:Double){
        self.uid = uid
        self.subject = subject
        self.displayName = displayName
        self.time = time
    }
    
    init(dic:NSMutableDictionary){
        self.uid = (dic["uid"] as! NSNumber).unsignedIntValue
        self.subject = dic["subject"] as! String
        self.displayName = dic["displayName"] as! String
        self.time = (dic["time"] as! NSNumber).doubleValue
        //self.htmlBody = dic["htmlBody"] as? String
        self.readed = (dic["readed"] as? NSNumber)?.integerValue ?? 0
    }
    
    func toDictionry()->NSMutableDictionary{
        
        let dic = NSMutableDictionary()
        dic["uid"] = NSNumber(unsignedInt: self.uid)
        dic["subject"] = self.subject
        dic["displayName"] = self.displayName
        dic["time"] = NSNumber(double: self.time)
        //dic["htmlBody"] = self.htmlBody
        dic["readed"] = NSNumber(integer: self.readed)
        return dic
    }
    
}