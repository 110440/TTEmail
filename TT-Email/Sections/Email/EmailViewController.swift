//
//  EmailViewController.swift
//  TT-Email
//
//  Created by tanson on 16/4/26.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

class EmailViewController: UITableViewController ,MenuViewDeleaget{
    
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
    
    lazy var menu:MenuView = {
        let w = self.view.bounds.width * 3.0/4.0
        let menu = MenuView(w: w, h: self.view.bounds.height)
        menu.delegate = self
        return menu
    }()
    
    lazy var reflashContol:UIRefreshControl = {
        let c = UIRefreshControl()
        c.addTarget(self , action: #selector(self.reflash(_:)), forControlEvents: .ValueChanged)
        return c
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.addSubview(self.reflashContol)
        self.tableView.tableFooterView = self.footView
        self.footView.addTarget(self, action: #selector(self.loadMore(_:)), forControlEvents: .TouchUpInside)
        
        let leftButton = UIBarButtonItem(image: UIImage(named:"menu"), style:.Plain, target: self, action:#selector(EmailViewController.onMenu))
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
        
        self.view.addSubview(self.menu)
        
        self.login()
    }

    func login(){
        
        //
        self.reflashContol.beginRefreshing()
        if let userName = APP.getCurLoginUserName(),let curAccount = APP.accountStore.getAccountForName(userName) {
            
            APP.curEmailAccount = curAccount
            self.menu.reloadData()
            
            // 本地数据
            let messages = APP.emailStore.getAllMessage(curAccount.username, folderName: APP.curFoldername )
            self.messages = messages
            self.tableView.reloadData()
            
            print("正在登陆。。。")
            APP.loginForIMAP(curAccount, completion: { (error) in
                
                if error == nil{
                    self.menu.reloadData()
                    print("登陆成功")
                    self.reflashContol.endRefreshing()
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
                    
                    var msg = "登陆失败"
                    if error!.code == MCOErrorCode.Authentication.rawValue {
                        msg = "登陆失败,请检查你的账号"
                    }
                    let aler = UIAlertView(title: "", message: msg, delegate: nil, cancelButtonTitle: "OK")
                    aler.show()
                }
                
            })
        }
    }
    
    func reflash(c:UIRefreshControl){
        print(c.refreshing)
    }
    
    func onMenu(){
        self.menu.showMenu()
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
        cell.selectionStyle = .None
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

    //MARK: MenuView delegate
    func numberOfSectionsForMenuView(view: MenuView) -> Int {
        return 3
    }
    func numberOfRowsInSectionForMenuView(view: MenuView, section: Int) -> Int {
        if section == 0{
            return 1
        }else if section == 2{
            return 1
        }
        return APP.curEmailAccount?.folders?.count ?? 0
    }
    func menuView(view: MenuView, willShowCell cell: UITableViewCell, indexPath: NSIndexPath) {
        if indexPath.section == 0{
            cell.textLabel?.text = APP.curEmailAccount?.username ?? ""
        }else if indexPath.section == 2{
            cell.textLabel?.text = "增加账号"
        }else{
            let name = APP.curEmailAccount?.folders![indexPath.row]
            cell.textLabel?.text = Utility.chineseFromEnglish(name!)
        }
    }
    
    func menuView(view: MenuView, selectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2{
            
            let imapHostName = "imap-mail.outlook.com"
            let imapPort:UInt32 = 993
            let smtpHostName = "smtp-mail.outlook.com"
            let smtpPort:UInt32 = 587
            let userName = "sanjinshutest@hotmail.com"
            let password = "sanjinshu110"
            
            let emailAccount = EmailAccount(IMAPHotname: imapHostName, IMAPPort: imapPort, SMTPHotname: smtpHostName, SMTPPort: smtpPort, username: userName, password: password,folders:[])
            
            APP.accountStore.addAccount(emailAccount)
            APP.setCurLoginUserName(userName)
            self.login()
        }else if indexPath.section == 1{
            APP.curFoldername = APP.curEmailAccount!.folders![indexPath.row]
            self.login()
        }else{
            print(APP.curEmailAccount?.username)
        }
    }
    
    func menuView(view: MenuView, titleForHeaderInSection section: Int) -> String? {
        if section == 1{
            return "文件夹"
        }
        return nil
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
