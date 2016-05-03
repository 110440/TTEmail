//
//  EmailViewController.swift
//  TT-Email
//
//  Created by tanson on 16/4/26.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

class EmailViewController: UITableViewController {
    
    var messages = [EmailMessage]()
    var messagesOffset:UInt64 = 0
    
    lazy var footView:UIButton = {
    
        let view = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width , height: 40))
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor(white: 0.8, alpha: 0.5).CGColor
        view.setTitle("加载更多...", forState: .Normal)
        view.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = self.footView
        self.footView.addTarget(self, action: #selector(self.loadMore(_:)), forControlEvents: .TouchUpInside)
        
        let leftButton = UIBarButtonItem(image: UIImage(named:"menu"), style:.Plain, target: self, action:#selector(EmailViewController.menu))
        self.navigationItem.leftBarButtonItem = leftButton
        
        let searchButton = UIBarButtonItem(image: UIImage(named: "search"), style: .Plain, target: self, action: #selector(self.search) )
        let newMsgButton = UIBarButtonItem(image: UIImage(named: "write"), style: .Plain, target: self, action: #selector(self.newMsg))
        self.navigationItem.rightBarButtonItems = [searchButton,newMsgButton]
        
        //
        self.tableView.registerNib(UINib(nibName: "EmailCell",bundle: nil) , forCellReuseIdentifier: "email")
        self.tableView.rowHeight = 65
        //self.tableView.tableFooterView = UIView(frame:CGRectZero)
        
        //
        self.navigationItem.title = "收件箱"
        
        if let userName = APP.getCurLoginUserName(),let curAccount = APP.accountStore.getAccountForName(userName) {
            // 本地数据
            let messages = APP.emailStore.getAllMessage(curAccount.username, folderName: APP.curFoldername )
            self.messages += messages
            self.tableView.reloadData()
            
            print("正在登陆。。。")
            APP.loginForIMAP(curAccount, completion: { (error) in
              
                if error == nil{
                    print("登陆成功")
                    APP.emailStore.getNewMessage(APP.curIMAPSession!, userName: APP.curEmailAccount!.username, folderName: APP.curFoldername, num: getMessageLenghtMaxNum, completion: { (error, msgs,range) in
                        
                        dispatch_async(dispatch_get_main_queue()){
                            if error == nil{
                                self.messages = msgs!
                                self.messagesOffset = UInt64( range!.location )
                                self.tableView.reloadData()
                            }else{
                                print(error)
                            }
                        }
                    })
                    
                }else{
                    print(error)
                    let aler = UIAlertView(title: "", message: "登陆失败", delegate: nil, cancelButtonTitle: "OK")
                    aler.show()
                }
                
            })
        }
    }

    func menu(){
        
    }
    func search(){
        
    }
    func newMsg(){
        
    }
    func loadMore(sender:UIButton){
        if self.messagesOffset > 1 {
            var start = self.messagesOffset - getMessageLenghtMaxNum
            start = start > 0 ? start:1
            APP.emailStore.getNextPageMessage(APP.curIMAPSession, folder: APP.curFoldername, start:start, completion: { (error, messages) in
                if error == nil{
                    dispatch_async(dispatch_get_main_queue()){
                        self.messages += messages!
                        self.messagesOffset =  start
                        self.tableView.reloadData()
                    }
                }else{
                    print(error)
                }
            })
        }
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
        return self.messages.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("email", forIndexPath: indexPath) as! EmailCell
        let data = self.messages[indexPath.row]
        cell.setData(data)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let detailVC = EmailDetailViewController(nibName: "EmailDetailViewController", bundle: nil)
        detailVC.message = self.messages[indexPath.row]
        detailVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(detailVC, animated: true)
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
