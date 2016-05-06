//
//  EmailStore.swift
//  TT-Email
//
//  Created by tanson on 16/4/29.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation


let getMessageLenghtMaxNum:UInt64 = 10

class EmailStore {
    
    private func getMessageTableForFolder(folderName:String,userName:String)->Table{
        let store = YTKKeyValueStore(DBWithName: userName)
        let table = Table(store: store, name: folderName)
        return table
    }
    
    // 保存msg到本地
    func updateMessage(userName:String,folderName:String,message:EmailMessage,key:String){
        let table = self.getMessageTableForFolder(folderName, userName: userName)
        let dic = message.toDictionry()
        table.putObject(dic, key: key)
    }
    
    
    func putMessages(userName:String,folderName:String,messages:[EmailMessage]){
        if messages.count < 0 {return}
        
        let oldMessage = self.getAllMessage(userName, folderName: folderName)
        
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
                self.deleteMessageBody(folderName, userName: userName, uid: oldMessage.uid)
            }
        }
        
        for message in messages{
            self.updateMessage(userName, folderName: folderName, message: message, key: String(message.uid))
        }
        
    }
    

    //
    func getAllMessage(userName:String,folderName:String)->[EmailMessage]{
        
        let table = self.getMessageTableForFolder(folderName, userName: userName)
        var allMessage = [EmailMessage]()
        let allObject = table.allObject()
        for object in allObject{
            let message = EmailMessage(dic: object as! NSMutableDictionary)
            allMessage.append(message)
        }
        return allMessage
    }
    
    func getNextPageMessage(imap:IMAPSession?, folder:String,start:UInt64,completion:(error:NSError?,messages:[EmailMessage]?)->Void){
        imap?.getMessageForFolder(folder, start: start, lenght: getMessageLenghtMaxNum-1, completion: { (error, messages) in
            if error == nil{
                var emailMessages = [EmailMessage]()
                for message in messages!{
                    let date = message.header.date.timeIntervalSince1970
                    let emailMsg = EmailMessage(uid: message.uid, subject: message.header.subject, displayName: message.header.from.displayName,time:date)
                    emailMessages.append(emailMsg)
                }
                completion(error: nil, messages: emailMessages.reverse())
            }else{
                completion(error: error, messages: nil)
            }
        })
    }

    // 获取 new msg 并存到本地
    func getNewMessage(imapSession:IMAPSession, userName:String,folderName:String,num:UInt64,completion:(error:NSError?,msgs:[EmailMessage]?,range:NSRange?)->Void){
        
        imapSession.getNewMessagesForFolder(folderName, num: num) { (error, messages,range) in
            if error == nil{
                var emailMessages = [EmailMessage]()
                for message in messages!{
                    let date = message.header.date.timeIntervalSince1970
                    let emailMsg = EmailMessage(uid: message.uid, subject: message.header.subject, displayName: message.header.from.displayName,time:date)
                    emailMessages.append(emailMsg)
                }
                emailMessages = emailMessages.reverse()
                self.putMessages(userName, folderName: folderName, messages: emailMessages)
                completion(error: nil, msgs: emailMessages,range: range)
            }else{
                completion(error: error, msgs: nil , range: nil)
            }
        }
    }
    
    private func getMessageBodyTableForFolder(userName:String)->Table{
        let store = YTKKeyValueStore(DBWithName: userName)
        let table = Table(store: store, name: "MessageBody")
        return table
    }
    
    func putMessageBody(folderName:String,userName:String,body:NSData,uid:UInt32){
        let table = self.getMessageBodyTableForFolder(userName)
        let key = "\(folderName)-\(uid)"
        if let string = NSString(data: body, encoding: NSUTF8StringEncoding){
            table.putString(string as String, key: key)
        }
    }
    
    func getMessageBody(folderName:String,username:String,uid:UInt32)->NSData?{
        let table = self.getMessageBodyTableForFolder(username)
        let key = "\(folderName)-\(uid)"
        if let body = table.stringForKey(key){
            return body.dataUsingEncoding(NSUTF8StringEncoding)
        }
        return nil
    }
    
    func deleteMessageBody(folder:String,userName:String,uid:UInt32){
        let table = self.getMessageBodyTableForFolder(userName)
        let key = "\(folder)-\(uid)"
        table.deleteBy(key)
    }
    
    ///
    func fetchMessageHtmlBody(imapSession:IMAPSession?,userName:String,folerName:String,uid:UInt32,completion:(error:NSError?,body:String?)->Void)->MCOIMAPBaseOperation?{
        
        let bodyData = self.getMessageBody(folerName, username: userName, uid: uid)
        
        if bodyData == nil {
            
            let op = imapSession?.getMessageBodyData(folerName, uid: uid, completion: { (error, data) in
                if error == nil{
                    self.putMessageBody(folerName, userName: userName, body: data!, uid: uid)
                    let messageParser = MCOMessageParser(data: data)
                    completion(error: nil, body: messageParser.htmlBodyRendering())
                }else{
                    completion(error: error, body: nil)
                }
            })
            return op
        }else{
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0), {
                let messageParser = MCOMessageParser(data: bodyData)
                completion(error: nil, body: messageParser.htmlBodyRendering())
            })
        }
        return nil
    }
    
    func fetchMessageTextBody(imapSession:IMAPSession?,userName:String,folerName:String,uid:UInt32,completion:(error:NSError?,body:String?)->Void)->MCOIMAPBaseOperation?{
        
        let bodyData = self.getMessageBody(folerName, username: userName, uid: uid)
        
        if bodyData == nil {
            
            let op = imapSession?.getMessageBodyData(folerName, uid: uid, completion: { (error, data) in
                if error == nil{
                    self.putMessageBody(folerName, userName: userName, body: data!, uid: uid)
                    let messageParser = MCOMessageParser(data: data)
                    completion(error: nil, body: messageParser.plainTextBodyRendering())
                }else{
                    completion(error: error, body: nil)
                }
            })
            return op
        }else{
            dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0), {
                let messageParser = MCOMessageParser(data: bodyData)
                completion(error: nil, body: messageParser.plainTextBodyRendering())
            })
            return nil
        }
    }
    
    func deleteMessage(imapSession:IMAPSession,userName:String, uid:UInt32,completion:(error:NSError?)->Void){
        let fromFolder = APP.curFoldername
        let toFolder = "Deleted"
        
        imapSession.moveMessage(UInt64(uid), fromFoldername: fromFolder, toFolername: toFolder) { (error) in
            if error == nil{
                let table = self.getMessageTableForFolder(fromFolder, userName: APP.curEmailAccount!.username)
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
}
