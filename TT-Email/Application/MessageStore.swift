//
//  MessageStore.swift
//  TT-Email
//
//  Created by tanson on 16/5/6.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import YTKKeyValueStore


let GET_MSG_NUM:UInt64 = 10

class MessageStore {
    
    private func getMessageTableForFolder(folderName:String)->Table{
        let store = YTKKeyValueStore(DBWithName:APP.curAccount!.username)
        let table = Table(store: store, name: folderName)
        return table
    }
    
    //获取本地文件 message
    func getAllMessage(folder:String)->[EmailMessage]{
        
        let table = self.getMessageTableForFolder(folder)
        var allMessage = [EmailMessage]()
        let allObject = table.allObject()
        for object in allObject{
            let message = EmailMessage(dic: object as! NSMutableDictionary)
            allMessage.append(message)
        }
        return allMessage
    }
    
    // 更新本地 message , 如果不存在，则增加
    func updateMessage(folder:String,message:EmailMessage){
        let table = self.getMessageTableForFolder(folder)
        let dic = message.toDictionry()
        table.putObject(dic, key:String(message.uid) )
    }
    
    func deleteMessage(folder:String,uid:UInt32){
        let table = self.getMessageTableForFolder(folder)
        table.deleteBy(String(uid))
    }
    
    //只保存最新几条
    func putMessages(folder:String,messages:[EmailMessage]){
        if messages.count < 0 {return}
        
        let oldMessage = self.getAllMessage(folder)
        
        for oldMessage in oldMessage{
            var isExist = false
            for newMessage in messages{
                if oldMessage.uid == newMessage.uid{
                    isExist = true
                    break
                }
            }
            if !isExist{
                // 清理body
                self.deleteMessageBody(folder, uid: oldMessage.uid)
                self.deleteMessage(folder,uid: oldMessage.uid)
            }
        }
        for message in messages{
            self.updateMessage(folder, message: message)
        }
    }
    
    var imapSession:MCOIMAPSession {
        return APP.curAccount!.IMAPSession
    }
    
    //所有文件夹
    func fetchAllFolders(session:MCOIMAPSession,completion:(error:NSError?,folders:[Folder]?)->Void)->MCOIMAPBaseOperation{
        return IMAPSessionAPI.fetchAllFolders(session, completion: { (error, folders) in
            if error == nil{
                var folderArray = [Folder]()
                for folderName in folders!{
                    let f = Folder(name: folderName, count: 0)
                    folderArray.append(f)
                }
                completion(error: nil, folders: folderArray)
            }else{
                completion(error: error, folders: nil)
            }
        })
    }
    
    func setMessageCountForFolder(folder:String,count:UInt64){
        APP.curAccount!.setMessageCountForFolder(folder, count: count)
        APP.accountStore.addAccount(APP.curAccount!)
    }
    
    //文件夹邮件数
    func getMessageCountFromNet(completion:(error:NSError?,count:UInt64)->Void)->MCOIMAPBaseOperation{
        let folder = APP.curFoldername
        return IMAPSessionAPI.getMessageCount(self.imapSession, folder: folder) { (error, count) in
            if error == nil{
                self.setMessageCountForFolder(APP.curFoldername, count: count)
            }
            completion(error: error, count: count)
        }
    }
    
    func getMessageCountFromLocal()->UInt64{
        return APP.curAccount!.getMessageCountForFolder(APP.curFoldername)
    }
    
    // 获取最新 n msg 并存到本地
    func getNewMessage(totals:UInt64,num:UInt64,completion:(error:NSError?,msgs:[EmailMessage]?,offset:UInt64)->Void)->MCOIMAPBaseOperation{
        
        let session = self.imapSession
        let folder = APP.curFoldername
        
        return IMAPSessionAPI.getNewMessages(session, folder:folder, totals:totals, num: num) { (error, messages, offset) in
            if error == nil{
                var emailMessages = [EmailMessage]()
                for message in messages!{
                    let date = message.header.date.timeIntervalSince1970
                    let emailMsg = EmailMessage(uid: message.uid, subject: message.header.subject, displayName: message.header.from.displayName,time:date)
                    if message.flags.rawValue & MCOMessageFlag.Seen.rawValue > 0{
                        emailMsg.readed = 1
                    }
                    emailMessages.append(emailMsg)
                }
                emailMessages = emailMessages.reverse()
                self.putMessages(folder, messages: emailMessages)
                
                completion(error: nil, msgs: emailMessages,offset: offset)
            }else{
                completion(error: error, msgs: nil,offset:offset)
            }
        }
    }
    
    // 获取旧的一页,不保存在本地
    func getNextPageMessage(offset:UInt64,completion:(error:NSError?,messages:[EmailMessage]?,offset:UInt64)->Void)->MCOIMAPBaseOperation?{
        
        if offset <= 1 {
            completion(error: nil, messages: [] ,offset: 1)
            return nil
        }
        
        let session = self.imapSession
        
        let start = max(offset - GET_MSG_NUM, 1)
        let lenght = offset - start - 1
        let folder = APP.curFoldername
        
        return IMAPSessionAPI.getMessages(session, folder: folder, start: start, lenght: lenght) { (error, messages) in
            if error == nil{
                var emailMessages = [EmailMessage]()
                for message in messages!{
                    let date = message.header.date.timeIntervalSince1970
                    let emailMsg = EmailMessage(uid: message.uid, subject: message.header.subject, displayName: message.header.from.displayName,time:date)
                    emailMessages.append(emailMsg)
                }
                completion(error: nil, messages: emailMessages.reverse() , offset: start)
            }else{
                completion(error: error, messages: nil,offset: 0)
            }
        }
    }
    
    private func getMessageBodyTable()->Table{
        let store = YTKKeyValueStore(DBWithName: APP.curAccount!.username)
        let table = Table(store: store, name: "MessageBody")
        return table
    }
    
    func putMessageBody(folder:String,body:NSData,uid:UInt32){
        let table = self.getMessageBodyTable()
        let key = "\(folder)-\(uid)"
        if let string = NSString(data: body, encoding: NSUTF8StringEncoding){
            table.putString(string as String, key: key)
        }
    }
    
    func getMessageBody(folder:String,uid:UInt32)->NSData?{
        let table = self.getMessageBodyTable()
        let key = "\(folder)-\(uid)"
        if let body = table.stringForKey(key){
            return body.dataUsingEncoding(NSUTF8StringEncoding)
        }
        return nil
    }
    
    func deleteMessageBody(folder:String,uid:UInt32){
        let table = self.getMessageBodyTable()
        let key = "\(folder)-\(uid)"
        table.deleteBy(key)
    }
    
    ///
    func fetchMessageHtmlBody(folder:String,uid:UInt32,completion:(error:NSError?,body:String?)->Void)->MCOIMAPBaseOperation?{
        
        let session = APP.curAccount!.IMAPSession
        let bodyData = self.getMessageBody(folder, uid: uid)
        if bodyData == nil {
            
            let op = IMAPSessionAPI.getMessageBodyData(session, folder: folder, uid: uid, completion: { (error, data) in
                if error == nil{
                    self.putMessageBody(folder, body: data!, uid: uid)
                    let messageParser = MCOMessageParser(data: data)
                    //TODO:saync?
                    completion(error: nil, body: messageParser.htmlBodyRendering())
                }else{
                    completion(error: error, body: nil)
                }
            })
            return op
            
        }else{
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_DEFAULT.rawValue), 0), {
                let messageParser = MCOMessageParser(data: bodyData)
                completion(error: nil, body: messageParser.htmlBodyRendering())
            })
        }
        return nil
    }
    
    func fetchMessageTextBody(folder:String,uid:UInt32,completion:(error:NSError?,body:String?)->Void)->MCOIMAPBaseOperation?{
        
        let session = APP.curAccount!.IMAPSession
        let bodyData = self.getMessageBody(folder, uid: uid)
        if bodyData == nil {
            
            let op = IMAPSessionAPI.getMessageBodyData(session, folder: folder, uid: uid, completion: { (error, data) in
                if error == nil{
                    self.putMessageBody(folder, body: data!, uid: uid)
                    let messageParser = MCOMessageParser(data: data)
                    //TODO:saync?
                    completion(error: nil, body: messageParser.plainTextBodyRendering())
                }else{
                    completion(error: error, body: nil)
                }
            })
            return op
            
        }else{
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0), {
                let messageParser = MCOMessageParser(data: bodyData)
                completion(error: nil, body: messageParser.plainTextBodyRendering())
            })
        }
        return nil
    }
    
    func deleteMessage(session:MCOIMAPSession,uid:UInt32,completion:(error:NSError?)->Void){
        let fromFolder = APP.curFoldername
        let toFolder = "Deleted"
        
        IMAPSessionAPI.moveMessage(session, uid: uid, fromFolder: fromFolder, toFolder: toFolder) { (error) in
            if error == nil{
                let table = self.getMessageTableForFolder(fromFolder)
                //if let messageData = table.objectForKey(String(uid)){
                //let message = EmailMessage(dic: messageData as! NSMutableDictionary )
                //add to delete folder
                //}
                table.deleteBy(String(uid))
                completion(error: nil)
            }else{
                completion(error: error)
            }
        }
    }
    
    func setMessageReaded(uid:UInt32,readed:Bool,completion:(error:NSError?)->Void){
        IMAPSessionAPI.setReaded(APP.curAccount!.IMAPSession, readed: readed, uid: uid, foldername: APP.curFoldername) { (error) in
            completion(error: error)
        }
    }
}