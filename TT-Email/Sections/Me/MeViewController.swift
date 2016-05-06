//
//  MeViewController.swift
//  TT-Email
//
//  Created by tanson on 16/4/28.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

class MeViewController: UITableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = "添加账号"
        return cell
    }
 
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0{
            
            let imapHostName = "imap-mail.outlook.com"
            let imapPort:UInt32 = 993
            let smtpHostName = "smtp-mail.outlook.com"
            let smtpPort:UInt32 = 587
            let userName = "sanjinshutest@hotmail.com"
            let password = "sanjinshu110"
            
            var account = Account(IMAPHotname: imapHostName, IMAPPort: imapPort, SMTPHotname: smtpHostName, SMTPPort: smtpPort, username: userName, password: password, folders: [])
            
            let hud = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
            hud.labelText = "正在验证账号..."
            
            IMAPSessionAPI.checkAccount(account.IMAPSession, completion: { (error) in
                
                if error == nil {
                    APP.messageStore.fetchAllFolders(account.IMAPSession, completion: { (error, folders) in
                        if error == nil{
                            
                            account.folders = folders
                            APP.accountStore.addAccount(account)
                            APP.setCurLoginUserName(userName)
                            APP.curAccount = account
                            
                            dispatch_async(dispatch_get_main_queue()){
                            hud.labelText = "验证成功！"
                            hud.hide(true, afterDelay: 1)
                            }
                            
                        }else{
                            Utility.showErrorMessage(error!)
                        }
                    })
                    
                }else{
                    Utility.showErrorMessage(error!)
                }
            })
            
            
            
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
