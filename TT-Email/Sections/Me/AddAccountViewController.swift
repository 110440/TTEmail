//
//  AddAccountViewController.swift
//  TT-Email
//
//  Created by tanson on 16/5/7.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit
import MBProgressHUD

private let titleMap = [
    ["账    号","密    码"],
    ["服务器","端    口"],
    ["服务器","端    口"],
]

private let placeMap = [
    ["输入账号","输入密码"],
    ["输入服务器","输入端口"],
    ["输入服务器","输入端口"],
]

class AddAccountViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "添加账号"
        self.tableView.registerNib(UINib(nibName: "AddAccountCell",bundle: nil) , forCellReuseIdentifier: "cell")
        let btn = UIBarButtonItem(title:" 确定", style: .Plain, target: self, action: #selector(self.add))
        self.navigationItem.rightBarButtonItem = btn
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.textFieldDidEndEditing(_:)), name: UITextFieldTextDidEndEditingNotification, object: nil)
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func textFieldDidEndEditing(n:NSNotification){
        let textField = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! AddAccountCell).valueView
        if let view =  n.object as? UITextField where view == textField {
            if let str = view.text{
            
                if let range = str.rangeOfString("@"){
                    let subStr = str.substringFromIndex(range.startIndex.advancedBy(1))
                    let IMAPtextField = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! AddAccountCell).valueView
                    let SMTPtextField = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) as! AddAccountCell).valueView
                    let IMAPHost = "imap.\(subStr)"
                    let SMTPHost = "smtp.\(subStr)"
                    IMAPtextField.text = IMAPHost
                    SMTPtextField.text = SMTPHost
                    
                }

            }
        }
    }
    
    func add(){
        
        let userNameStr = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! AddAccountCell).valueView.text
        let passworkStr = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! AddAccountCell).valueView.text
        
        let imapHostStr = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! AddAccountCell).valueView.text
        let imapPortStr = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 1)) as! AddAccountCell).valueView.text
        
        let smtpHostStr = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) as! AddAccountCell).valueView.text
        let smtpPortStr = (self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 2)) as! AddAccountCell).valueView.text
        
        guard let userName = userNameStr , let password = passworkStr ,let imapHost = imapHostStr , let imapPort = UInt32(imapPortStr ?? " "),let smtpHost = smtpHostStr,let smtpPort = UInt32(smtpPortStr ?? " " ) where userName.characters.count > 0 && password.characters.count > 0 && imapHost.characters.count > 0 && smtpHost.characters.count > 0 else {
            let a = UIAlertView(title: nil, message: "请输入完整", delegate: nil, cancelButtonTitle: "好的")
            a.show()
            return
        }
        
        self.view.endEditing(true)
        
        var account = Account(IMAPHotname: imapHost, IMAPPort: imapPort, SMTPHotname: smtpHost, SMTPPort: smtpPort, username: userName, password: password, folders: [])
        
        let hud = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
        hud.labelText = "正在验证账号..."
        
        IMAPSessionAPI.checkAccount(account.IMAPSession, completion: { (error) in
            
            if error == nil {
                APP.messageStore.fetchAllFolders(account.IMAPSession, completion: { (error, folders) in
                    if error == nil{
                        
                        account.folders = folders
                        APP.accountStore.addAccount(account)
                        //APP.setCurLoginUserName(userName)
                        //APP.curAccount = account
                        
                        dispatch_async(dispatch_get_main_queue()){
                            hud.labelText = "验证成功！"
                            hud.hide(true, afterDelay: 0.7)
                            self.performSelector(#selector(self.popViewController), withObject: nil, afterDelay:1)
                        }
                        
                    }else{
                        hud.labelText = "验证失败！"
                        hud.hide(true, afterDelay: 1)
                        Utility.showErrorMessage(error!)
                    }
                })
                
            }else{
                hud.labelText = "验证失败！"
                hud.hide(true, afterDelay: 1)
                Utility.showErrorMessage(error!)
            }
        })
    }
    
    func popViewController(){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! AddAccountCell

        cell.titleLab.text = titleMap[indexPath.section][indexPath.row]
        cell.valueView.placeholder = placeMap[indexPath.section][indexPath.row]
        cell.selectionStyle = .None
        
//        if indexPath.section == 0 && indexPath.row == 0{
//            cell.inputView.
//        }
        if indexPath.section == 1 && indexPath.row == 1{
            cell.valueView.text = String(993)
        }
        if indexPath.section == 2 && indexPath.row == 1{
            cell.valueView.text = String(587)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "账号"
        case 1:
            return "IMAP"
        default:
            return "SMTP"
            
        }
    }
    
}
