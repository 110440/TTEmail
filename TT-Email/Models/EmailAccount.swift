//
//  UserModel.swift
//  TT-Email
//
//  Created by tanson on 16/4/26.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

struct EmailAccount {
    
    let IMAPHotname:String
    let IMAPPort:UInt32
    let SMTPHotname:String
    let SMTPPort:UInt32
    
    let username:String
    let password:String
    
    var folders:[String]?
    
    static func fromDictionry(dic:NSDictionary)->EmailAccount{
        let username = dic["username"] as! String
        let password = dic["password"] as! String
        let imapHostname = dic["IMAPHotname"] as! String
        let imapPort = (dic["IMAPPort"] as! NSNumber).unsignedIntValue
        let smtpHostname = dic["SMTPHotname"] as! String
        let smtpPort = (dic["SMTPPort"] as! NSNumber).unsignedIntValue
        let folders = dic["folders"] as! [String]
        
//        var folders = [Folder]()
//        let foldersData = dic["folders"] as! [NSMutableDictionary]
//        for folder in foldersData{
//            let f = Folder.fromDictionry(folder)
//            folders.append(f)
//        }
        
        return EmailAccount(IMAPHotname: imapHostname, IMAPPort: imapPort, SMTPHotname: smtpHostname, SMTPPort: smtpPort, username: username, password: password ,folders: folders)
    }
    
    func toDictionry()->NSMutableDictionary{
        let dic = NSMutableDictionary()
        dic["username"] = self.username
        dic["password"] = self.password
        dic["IMAPHotname"] = self.IMAPHotname
        dic["IMAPPort"] = NSNumber(unsignedInt: self.IMAPPort)
        dic["SMTPHotname"] = self.SMTPHotname
        dic["SMTPPort"] = NSNumber(unsignedInt: self.SMTPPort)
        
        dic["folders"] = self.folders
        return dic
    }
    
}
