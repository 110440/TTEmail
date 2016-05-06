//
//  EmailAPI.swift
//  TT-Email
//
//  Created by tanson on 16/4/25.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

class SMTPSession {
    
    let hostname:String
    let port:UInt32
    let username:String
    let password:String
    var session:MCOSMTPSession?
    
    init(hostname:String,port:UInt32,username:String,password:String){
        self.hostname = hostname
        self.port = port
        self.username = username
        self.password = password
    }
    
    func login(completion:(error:NSError?)->Void){
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = self.hostname
        smtpSession.port = self.port
        smtpSession.username = self.username
        smtpSession.password = self.password
        smtpSession.connectionType = .StartTLS
        
        let loginOperation = smtpSession.loginOperation()
        loginOperation.start { (error) in
            if let e = error{
                print("SMTP login error:\(e)")
                completion(error: e)
            }else{
                self.session = smtpSession
                completion(error: nil)
            }
        }
    }
    
    func sendMessage(toEmailAddr:String,subject:String,textBody:String,completion:(error:NSError?)->Void){
        
        guard let session = self.session else{
            let error = NSError(domain: "no login", code: -1, userInfo: nil)
            completion(error: error)
            return
        }
        
        let messageBuilder = MCOMessageBuilder()
        messageBuilder.header.from = MCOAddress(displayName: "", mailbox: self.username)
        messageBuilder.header.to = [MCOAddress(mailbox: toEmailAddr)]
        messageBuilder.header.subject = subject
        messageBuilder.textBody = textBody
        
        let sendData = messageBuilder.data()
        let sendOP = session.sendOperationWithData(sendData)
        sendOP.start { (error) in
            completion(error: error)
        }
    }
}

//

class IMAPSession {
    
    var session:MCOIMAPSession
    
    private init(session:MCOIMAPSession){
        self.session = session
    }

    static func sessionWithLogin(hostname:String,port:UInt32,username:String,password:String,completion:(error:NSError?,session:IMAPSession?,folders:[String]?)->Void){
        
        let session = MCOIMAPSession()
        session.hostname = hostname
        session.port = port
        session.connectionType = .TLS
        session.username = username
        session.password = password
        let checkOp = session.checkAccountOperation()
        checkOp.start { (error) in
            if error != nil{
                completion(error: error,session:nil,folders: nil)
            }else{
                let fetchOP = session.fetchAllFoldersOperation()
                fetchOP.start { (error, folders) in
                    if error != nil{
                        completion(error: error,session: nil,folders: nil)
                    }else{
                        var ret = [String]()
                        for folder in folders!{
                            let folderName = session.defaultNamespace.componentsFromPath(folder.path).first as! String
                            ret.append(folderName)
                        }
                        let s = IMAPSession(session: session)
                        completion(error: nil,session: s , folders:ret)
                    }
                }
            }
        }
    }

    
    private func fetchAllFolders(completion:(error:NSError?,folders:[String]?)->Void){
        
        let fetchOP = self.session.fetchAllFoldersOperation()
        fetchOP.start { (error, folders) in
            if error != nil{
                completion(error: error,folders: nil)
            }else{
                var ret = [String]()
                for folder in folders!{
                    let folderName = self.session.defaultNamespace.componentsFromPath(folder.path).first as! String
                    ret.append(folderName)
                }
                completion(error: nil,folders: ret)
            }
        }
    }
    

    func getMessageForFolder(folername:String,start:UInt64,lenght:UInt64,completion:(error:NSError?,messages:[MCOIMAPMessage]?)->Void){
        
        // fetch message
        let msgIndexSet = MCOIndexSet(range: MCORange(location:start, length: lenght))
        let requestKind:MCOIMAPMessagesRequestKind = [.Headers,.HeaderSubject,.Flags,.InternalDate,.Structure]
        let fetchMsgOp = session.fetchMessagesByNumberOperationWithFolder(folername, requestKind: requestKind, numbers: msgIndexSet)
        
        fetchMsgOp.start({ (error, massges, indexSet) in
            if error == nil{
                completion(error: nil, messages: massges as? [MCOIMAPMessage] )
            }else{
                completion(error: error, messages: nil)
            }
        })
    }
    
    func getMessageCount(folderName:String,completion:(count:UInt64)->Void)->MCOIMAPBaseOperation{
        let folderInfoOp = session.folderInfoOperation(folderName)
        folderInfoOp.start{ (error, info) in
            if let _ = error{
                completion(count: 0)
            }else{
                completion(count: UInt64(info!.messageCount))
            }
        }
        return folderInfoOp!
    }
    
    //最新n条消息
    func getNewMessagesForFolder(folderName:String,num:UInt64,completion:(error:NSError?,messages:[MCOIMAPMessage]?,range:NSRange?)->Void){
        
        let folderInfoOp = session.folderInfoOperation(folderName)
        folderInfoOp.start{ (error, info) in
            if let error = error{
                completion(error: error, messages: nil,range: nil)
                return
            }else{
                
                // fetch message
                let msgCount = UInt64(info!.messageCount)
                print("messageCount:\(msgCount)")
                if msgCount <= 0 {
                    completion(error: nil, messages:[], range: NSRange(location:1,length:0) )
                    return
                }
                
                var length = num - 1
                let start = msgCount >= length ? msgCount - length : 1
                length = msgCount >= length ? length:msgCount-1
                print("messageIndexStart-lenght:\(start)-\(length)")
                
                let msgIndexSet = MCOIndexSet(range: MCORange(location:start, length: length))
                let requestKind:MCOIMAPMessagesRequestKind = [.Headers,.HeaderSubject,.Flags,.InternalDate,.Structure]
                let fetchMsgOp = self.session.fetchMessagesByNumberOperationWithFolder(folderName, requestKind: requestKind, numbers: msgIndexSet)
                
                fetchMsgOp.start({ (error, massges, indexSet) in
                    if error == nil{
                        let range = NSRange(location: Int(start),length:Int(length))
                        completion(error: nil, messages: massges as? [MCOIMAPMessage],range: range)
                    }else{
                        completion(error: error, messages: nil,range: nil)
                    }
                })
            }
        }
    }
    
    
    func getMessageBodyData(folderName:String,uid:UInt32,completion:(error:NSError?,data:NSData?)->Void)->MCOIMAPFetchContentOperation{
        let messageOp = self.session.fetchMessageOperationWithFolder(folderName, uid: uid)
        messageOp?.start({ (error, data) in
            if error == nil{
                completion(error: nil, data: data)
            }else{
                completion(error: error, data: nil)
            }
        })
        return messageOp!
    }
    
    
    // 拷贝
    func copyMessage(uids:UInt64, fromFoldername:String, toFolername:String,completion:(error:NSError?)->Void)->MCOIMAPCopyMessagesOperation {
        let indexSet = MCOIndexSet(index: uids)
        let op = self.session.copyMessagesOperationWithFolder(fromFoldername, uids: indexSet, destFolder: toFolername)
        op?.start({ (error, destUids) in
            completion(error: error)
        })
        return op!
    }
    
    // 移动
    func moveMessage(uids:UInt64,fromFoldername:String,toFolername:String,completion:(error:NSError?)->Void)->MCOIMAPBaseOperation{
        
        var operation:MCOIMAPBaseOperation?
        operation = self.copyMessage(uids, fromFoldername: fromFoldername, toFolername: toFolername) { (error) in
            if error != nil {
                completion(error: error)
            }else{
                //copy 成功后 设置删除 flags
                let uids = MCOIndexSet(index: uids)
                let flagsOp = self.session.storeFlagsOperationWithFolder(fromFoldername, uids: uids, kind: .Set, flags: .Deleted)
                flagsOp?.start({ (error) in
                    if error != nil {
                        completion(error: error)
                    }else{
                        //设置 flags 成功后,清理文件夹
                        let expungeOp = self.session.expungeOperation(fromFoldername)
                        expungeOp?.start({ (error) in
                            completion(error: error)
                        })
                        operation = expungeOp
                    }
                })
                operation = flagsOp
            }
        }
        return operation!
    }
    
    func setReaded(readed:Bool,uids:UInt64,foldername:String,completion:(error:NSError?)->Void){
        let uids = MCOIndexSet(index: uids)
        let kind:MCOIMAPStoreFlagsRequestKind = readed ? .Set : .Remove
        let flagsOp = self.session.storeFlagsOperationWithFolder(foldername, uids:uids, kind: kind, flags: .Seen)
        flagsOp?.start({ (error) in
            completion(error: error)
        })
    }
    
    func createDraft(data:NSData , completion:(error:NSError?)->Void){
        
        let foldername = self.session.defaultNamespace.pathForComponents(["草稿箱"])
        let op = self.session.appendMessageOperationWithFolder(foldername, messageData: data, flags: .Draft)
        op?.start({ (error, createdUID) in
            completion(error: error)
        })
    }

}
