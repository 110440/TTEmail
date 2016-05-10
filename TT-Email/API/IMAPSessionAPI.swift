//
//  IMAPSessionAPI.swift
//  TT-Email
//
//  Created by tanson on 16/5/6.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation

class IMAPSessionAPI{
    
    //验证账号
    static func checkAccount(session:MCOIMAPSession,completion:(error:NSError?)->Void)->MCOIMAPBaseOperation{
        let op = session.checkAccountOperation()
        op.start(completion)
        return op!
    }
    
    //获取所有文件夹名字
    static func fetchAllFolders(session:MCOIMAPSession,completion:(error:NSError?,folders:[String]?)->Void)->MCOIMAPBaseOperation{
        let op = session.fetchAllFoldersOperation()
        op.start { (error, folders) in
            if error != nil{
                completion(error: error,folders: nil)
            }else{
                var ret = [String]()
                for folder in folders!{
                    let folderName = session.defaultNamespace.componentsFromPath(folder.path).first as! String
                    ret.append(folderName)
                }
                completion(error: nil,folders: ret)
            }
        }
        return op!
    }
    
    //文件夹邮件数
    static func getMessageCount(session:MCOIMAPSession,folder:String,completion:(error:NSError?,count:UInt64)->Void)->MCOIMAPBaseOperation{
        let op = session.folderInfoOperation(folder)
        op.start { (error, info) in
            if error == nil{
                completion(error: nil, count: UInt64(info!.messageCount))
            }else{
                completion(error: error, count: 0)
            }
        }
        return op!
    }
    
    // 获取最新 n 条邮件
    // totals   先调用 getMessageCount() 取得邮件数目
    // num      要获取的邮件数目
    static func getNewMessages(session:MCOIMAPSession,folder:String,totals:UInt64,num:UInt64,completion:(error:NSError?,messages:[MCOIMAPMessage]?,offset:UInt64)->Void)->MCOIMAPBaseOperation{
        
        var length = num - 1
        let start = totals > length ? (totals - length):1
        
        length = totals > length ? length:totals-1
        
        print("messageIndexStart-lenght:\(start)-\(length)")
        
        return self.getMessages(session, folder: folder, start: start, lenght: length) { (error, messages) in
            if error == nil{
                completion(error: nil, messages: messages,offset:start)
            }else{
                completion(error: error, messages:nil,offset:0)
            }
        }
    }
    
    static func getMessages(session:MCOIMAPSession,folder:String,start:UInt64,lenght:UInt64,completion:(error:NSError?,messages:[MCOIMAPMessage]?)->Void)->MCOIMAPBaseOperation{
        
        let msgIndexSet = MCOIndexSet(range: MCORange(location:start, length: lenght))
        let requestKind:MCOIMAPMessagesRequestKind = [.Headers,.HeaderSubject,.Flags,.InternalDate,.Structure]
        let op = session.fetchMessagesByNumberOperationWithFolder(folder, requestKind: requestKind, numbers: msgIndexSet)
        
        op.start({ (error, massges, indexSet) in
            if error == nil{
                completion(error: nil, messages: massges as? [MCOIMAPMessage] )
            }else{
                completion(error: error, messages: nil)
            }
        })
        return op!
    }
    
    // 获取 邮件主体
    static func getMessageBodyData(session:MCOIMAPSession,folder:String,uid:UInt32,completion:(error:NSError?,data:NSData?)->Void)->MCOIMAPBaseOperation{
        let op = session.fetchMessageOperationWithFolder(folder, uid: uid)
        op.start({ (error, data) in
            if error == nil{
                completion(error: nil, data: data)
            }else{
                completion(error: error, data: nil)
            }
        })
        return op!
    }
    
    
    // 拷贝到另一个文件夹
    static func copyMessage(session:MCOIMAPSession,uid:UInt32, fromFolder:String, toFolder:String,completion:(error:NSError?)->Void)->MCOIMAPCopyMessagesOperation {
        let indexSet = MCOIndexSet(index:UInt64(uid))
        let op = session.copyMessagesOperationWithFolder(fromFolder, uids: indexSet, destFolder: toFolder)
        op.start({ (error, destUids) in
            completion(error: error)
        })
        return op!
    }
    
    // 移动邮件到另一个文件夹
    static func moveMessage(session:MCOIMAPSession,uid:UInt32,fromFolder:String,toFolder:String,completion:(error:NSError?)->Void)->MCOIMAPBaseOperation{
        
        var operation:MCOIMAPBaseOperation?
        operation = self.copyMessage(session, uid:uid, fromFolder:fromFolder, toFolder:toFolder){ error in
 
            if error != nil {
                completion(error: error)
            }else{
                //copy 成功后 设置删除 flags
                let uids = MCOIndexSet(index:UInt64(uid))
                let flagsOp = session.storeFlagsOperationWithFolder(fromFolder, uids: uids, kind: .Set, flags: .Deleted)
                flagsOp.start({ (error) in
                    if error != nil {
                        completion(error: error)
                    }else{
                        //设置 flags 成功后,清理文件夹
                        let expungeOp = session.expungeOperation(fromFolder)
                        expungeOp.start({ (error) in
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
    
    // 设置读标志
    static func setReaded(session:MCOIMAPSession ,readed:Bool,uid:UInt32,foldername:String,completion:(error:NSError?)->Void)->MCOIMAPBaseOperation{
        let uids = MCOIndexSet(index:UInt64(uid))
        let kind:MCOIMAPStoreFlagsRequestKind = readed ? .Set : .Remove
        let flagsOp = session.storeFlagsOperationWithFolder(foldername, uids:uids, kind: kind, flags: .Seen)
        flagsOp?.start({ (error) in
            completion(error: error)
        })
        return flagsOp!
    }
    
    // 保存草稿箱
    static func createDraft(session:MCOIMAPSession,data:NSData , completion:(error:NSError?)->Void)->MCOIMAPBaseOperation{
        
        let foldername = "Drafts"
        let op = session.appendMessageOperationWithFolder(foldername, messageData: data, flags: .Draft)
        op?.start({ (error, createdUID) in
            completion(error: error)
        })
        return op!
    }
    
}