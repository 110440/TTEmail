//
//  UserModel.swift
//  TT-Email
//
//  Created by tanson on 16/4/26.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

struct Account {
    
    let IMAPHotname:String
    let IMAPPort:UInt32
    let SMTPHotname:String
    let SMTPPort:UInt32
    
    let username:String
    let password:String
    
    var folders:[Folder]?
    
    var IMAPSession:MCOIMAPSession {
        let session = MCOIMAPSession()
        session.hostname = self.IMAPHotname
        session.port = self.IMAPPort
        session.connectionType = .TLS
        session.username = username
        session.password = password
        return session
    }
    
    static func fromDictionry(dic:NSDictionary)->Account{
        let username = dic["username"] as! String
        let password = dic["password"] as! String
        let imapHostname = dic["IMAPHotname"] as! String
        let imapPort = (dic["IMAPPort"] as! NSNumber).unsignedIntValue
        let smtpHostname = dic["SMTPHotname"] as! String
        let smtpPort = (dic["SMTPPort"] as! NSNumber).unsignedIntValue
        
        var folders = [Folder]()
        let folderData = dic["folders"] as! [NSMutableDictionary]
        for data in folderData{
            let folder = Folder.fromDictionry(data)
            folders.append(folder)
        }
        
        return Account(IMAPHotname: imapHostname, IMAPPort: imapPort, SMTPHotname: smtpHostname, SMTPPort: smtpPort, username: username, password: password ,folders: folders)
    }
    
    func toDictionry()->NSMutableDictionary{
        let dic = NSMutableDictionary()
        dic["username"] = self.username
        dic["password"] = self.password
        dic["IMAPHotname"] = self.IMAPHotname
        dic["IMAPPort"] = NSNumber(unsignedInt: self.IMAPPort)
        dic["SMTPHotname"] = self.SMTPHotname
        dic["SMTPPort"] = NSNumber(unsignedInt: self.SMTPPort)
        
        var foldersData = [NSMutableDictionary]()
        for folder in self.folders ?? []{
            let data = folder.toDictionry()
            foldersData.append(data)
        }
        dic["folders"] = foldersData
        return dic
    }
    
    func getMessageCountForFolder(folderName:String)->UInt64{
        for folder in self.folders ?? []{
            if folder.name == folderName {
                return folder.count
            }
        }
        return 0
    }
    
    mutating func setMessageCountForFolder(folderName:String,count:UInt64){
        let folders = self.folders ?? []
        for var folder in folders {
            if folder.name == folderName {
                folder.count = count
            }
        }
        self.folders = folders
    }
    
}
