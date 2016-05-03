//
//  EmailCell.swift
//  TT-Email
//
//  Created by tanson on 16/4/26.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

let colors:[UIColor] = [
    UIColor(red: 39.0/255.0, green: 105.0/255.0, blue: 176.0/255.0, alpha: 1),
    UIColor(red: 44.0/255.0, green: 56.0/255.0, blue: 114.0/255.0, alpha: 1),
    UIColor(red: 195.0/255.0, green: 66.0/255.0, blue: 145.0/255.0, alpha: 1),
    UIColor(red: 172.0/255.0, green: 40.0/255.0, blue: 28.0/255.0, alpha: 1),
    UIColor(red: 249.0/255.0, green: 154.0/255.0, blue: 0/255.0, alpha: 1),
    UIColor(red: 127.0/255.0, green: 165.0/255.0, blue: 0/255.0, alpha: 1),
    UIColor(red: 39.0/255.0, green: 145.0/255.0, blue: 111.0/255.0, alpha: 1),
    UIColor(red: 122.0/255.0, green: 95.0/255.0, blue: 73.0/255.0, alpha: 1)
]

class EmailCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!{
        didSet{
            //iconView.layer.cornerRadius = 32/2
            iconView.backgroundColor = UIColor.lightGrayColor()
        }
    }
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var titleLab: UILabel!
    @IBOutlet weak var contentLab: UILabel!
    
    @IBOutlet weak var name: UILabel!
    
    var getTextBodyOp:MCOIMAPBaseOperation?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.contentLab.text = ""
        self.getTextBodyOp?.cancel()
    }
    
    func setData(data:EmailMessage) {
        self.titleLab.text = data.subject
        self.nameLab.text = data.displayName
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)){
            let name = data.displayName.substringToIndex(data.displayName.startIndex.advancedBy(2))
            let hash = name.hash
            let colorIndex = hash % colors.count
            let color = colors[colorIndex]
            dispatch_async(dispatch_get_main_queue()){
                self.name.text = name
                self.iconView.backgroundColor = color
            }
        }
        
        
        self.getTextBodyOp = APP.emailStore.fetchMessageTextBody(APP.curIMAPSession, userName:APP.curEmailAccount!.username, folerName: APP.curFoldername, uid:data.uid, completion: {[weak self] (error, body) in
            guard let wself = self else {return}
            if error == nil{
                let text = Utility.removeURLForString(body ?? " " )
                let lenght = text.characters.count > 100 ? 100:text.characters.count
                let subStr = text.substringToIndex(text.startIndex.advancedBy(lenght))
                dispatch_async(dispatch_get_main_queue()){
                    wself.contentLab.text = subStr
                }
            }
            
        })
        
    }
    
}
