//
//  Utility.swift
//  TT-Email
//
//  Created by tanson on 16/4/26.
//  Copyright © 2016年 tanson. All rights reserved.
//

import Foundation
import UIKit


extension NSRange {
    func stringRangeForText(string: String) -> Range<String.Index> {
        let start = string.startIndex.advancedBy(self.location)
        let end = start.advancedBy(self.length)
        return start..<end
    }
}

extension String{
    
    func sizeForFont( font:UIFont?,size:CGSize,lineBreakMode:NSLineBreakMode)->CGSize {
        
        let font = font ?? UIFont.systemFontOfSize(12)
        var attr = [String:AnyObject]()
        attr[NSFontAttributeName] = font
        if lineBreakMode != NSLineBreakMode.ByWordWrapping{
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode
            attr[NSParagraphStyleAttributeName] = paragraphStyle
        }
        let rect = self.boundingRectWithSize(size, options: [.UsesLineFragmentOrigin,.UsesFontLeading], attributes: attr, context: nil)
        return rect.size
    }
    
    func heightForFont(font:UIFont,width:Float)->Float{
        let size = self.sizeForFont(font, size: CGSize(width: CGFloat(width), height: CGFloat(HUGE) ), lineBreakMode: NSLineBreakMode.ByWordWrapping)
        return Float(size.height)
    }
}

class Utility {
    
    static func removeURLForString(srcStr:String)->String{
        
        let regulaStr =  "((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)"
        
        var desStr = srcStr
        do{
            let regex = try NSRegularExpression(pattern: regulaStr, options: .CaseInsensitive)
            
            var firstMatch = regex.firstMatchInString(desStr, options: [], range: NSRange(location: 0,length: desStr.characters.count) )
            while let match = firstMatch {
                let range = match.range
                desStr.removeRange(range.stringRangeForText(desStr))
                desStr = desStr.stringByReplacingOccurrencesOfString("()", withString: "")
                firstMatch = regex.firstMatchInString(desStr, options: [], range: NSRange(location: 0,length: desStr.characters.count) )
            }
            
        }catch{
            return srcStr
        }
        return desStr
    }
    
    static func showErrorMessage(error:NSError){
        if error.code == MCOErrorCode.Authentication.rawValue{
            let msg = "连接错误，请检查你的账号设置！"
            let alert = UIAlertView(title:nil, message: msg, delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }else{
            print("error:\(error)")
        }
    }
    
    static func chineseFromEnglish(string:String)->String{
        let map = [
            "Notes":"Notes",
            "Drafts":"草稿箱",
            "Outbox":"Outbox",
            "Junk":"垃圾箱",
            "INBOX":"收件箱",
            "Sent":"已发送",
            "Deleted":"已删除"
        ]
        return map[string] ?? string
    }
    
    static func englishFromChinese(string:String)->String{
        let map = [
            "Notes":"Notes",
            "草稿箱":"Drafts",
            "Outbox":"Outbox",
            "垃圾箱":"Junk",
            "收件箱":"INBOX",
            "已发送":"Sent",
            "已删除":"Deleted"
        ]
        return map[string] ?? string
    }
    
}