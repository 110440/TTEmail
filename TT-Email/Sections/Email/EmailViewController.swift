//
//  EmailViewController.swift
//  TT-Email
//
//  Created by tanson on 16/4/26.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

class EmailViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,MenuViewDeleaget{
    
    var messages = [EmailMessage]()
    var messagesOffset:UInt64 = 0
    var op:MCOIMAPBaseOperation?
    
    lazy var tableView:UITableView = {
        let view = UITableView(frame: self.view.bounds)
        view.delegate = self
        view.dataSource = self
        view.registerNib(UINib(nibName: "EmailCell",bundle: nil) , forCellReuseIdentifier: "email")
        return view
    }()
    
    lazy var footView:UIButton = {
        let view = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width , height: 40))
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor(white: 0.8, alpha: 0.5).CGColor
        view.setTitle("加载更多...", forState: .Normal)
        view.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        return view
    }()
    
    lazy var menu:MenuView = {
        let w = self.view.bounds.width * 2.0/3.0
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
        self.navigationController?.navigationBar.translucent = false
        self.edgesForExtendedLayout = .Bottom
        
        self.view.addSubview(self.tableView)
        self.tableView.addSubview(self.reflashContol)
        self.tableView.tableFooterView = self.footView
        self.tableView.rowHeight = 65
        
        self.footView.addTarget(self, action: #selector(self.loadMore(_:)), forControlEvents: .TouchUpInside)
        
        self.view.addSubview(self.menu)
        self.navigationItem.title = "收件箱"
        
        let leftButton = UIBarButtonItem(image: UIImage(named:"menu"), style:.Plain, target: self, action:#selector(EmailViewController.onMenu))
        self.navigationItem.leftBarButtonItem = leftButton
        
        let searchButton = UIBarButtonItem(image: UIImage(named: "search"), style: .Plain, target: self, action: #selector(self.search) )
        let newMsgButton = UIBarButtonItem(image: UIImage(named: "write"), style: .Plain, target: self, action: #selector(self.newMsg))
        self.navigationItem.rightBarButtonItems = [searchButton,newMsgButton]

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.recveNotify), name: "changeAccount", object: nil)
        
        if let _ = APP.curAccount{
            self.showDataFromLocal()
            self.getNewMessages()
        }
    }
    
    func showDataFromLocal(){
        let messages = APP.messageStore.getAllMessage(APP.curFoldername)
        self.messages = messages
        self.tableView.reloadData()
        let count = APP.messageStore.getMessageCountFromLocal()
        self.messagesOffset = count - UInt64(self.messages.count)
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func recveNotify(){
        self.reflashContol.endRefreshing()
        self.showDataFromLocal()
        self.getNewMessages()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.menu.reloadData()
    }
    
    func getNewMessages(){
        
        self.op?.cancel()
        
        guard var _ = APP.curAccount else { return }
        
        if self.reflashContol.refreshing == false{
            self.reflashContol.beginRefreshing()
        }
        
        let oldCount = APP.messageStore.getMessageCountFromLocal()
        self.op = APP.messageStore.getMessageCountFromNet{ (error, newCount) in
            
            if error != nil {
                Utility.showErrorMessage(error!)
                self.reflashContol.endRefreshing()
                return
            }
            
            if newCount <= oldCount {
                self.reflashContol.endRefreshing()
                return
            }
            
            self.op = APP.messageStore.getNewMessage(newCount, num: GET_MSG_NUM ) { (error, msgs, offset) in
                
                dispatch_async(dispatch_get_main_queue()){
                    if error == nil{
                        self.messages = msgs!
                        self.messagesOffset = offset
                        self.tableView.reloadData()
                    }else{
                        APP.messageStore.setMessageCountForFolder(APP.curFoldername, count:oldCount)
                        Utility.showErrorMessage(error!)
                    }
                    self.reflashContol.endRefreshing()
                }
            }
        }
    }

    func loadMore(sender:UIButton){
        
        if self.messagesOffset <= 1{
            return
        }
        
        APP.messageStore.getNextPageMessage(self.messagesOffset) { (error, messages, offset) in
            if error == nil{
                dispatch_async(dispatch_get_main_queue()){
                    self.messages += messages!
                    self.messagesOffset = offset
                    self.tableView.reloadData()
                }
            }else{
                Utility.showErrorMessage(error!)
            }
        }
    }
    
    func reflash(c:UIRefreshControl){
        self.getNewMessages()
    }
    
    func onMenu(){
        self.menu.showMenu()
    }
    func search(){
        
    }
    func newMsg(){
        
    }
    

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.messages.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("email", forIndexPath: indexPath) as! EmailCell
        cell.selectionStyle = .None
        let data = self.messages[indexPath.row]
        cell.setData(data)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let detailVC = EmailDetailViewController(nibName: "EmailDetailViewController", bundle: nil)
        detailVC.message = self.messages[indexPath.row]
        detailVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(detailVC, animated: true)
    }

    //MARK: MenuView delegate
    func numberOfSectionsForMenuView(view: MenuView) -> Int {
        return 2
    }
    
    func numberOfRowsInSectionForMenuView(view: MenuView, section: Int) -> Int {
        if section == 0{
            return 1
        }
        return APP.curAccount?.folders?.count ?? 0
    }
    
    func menuView(view: MenuView, willShowCell cell: UITableViewCell, indexPath: NSIndexPath) {
        if indexPath.section == 0{
            cell.textLabel?.text = APP.curAccount?.username ?? ""
        }else{
            let name = APP.curAccount?.folders?[indexPath.row].name
            cell.textLabel?.text = Utility.chineseFromEnglish(name!)
        }
    }
    
    func menuView(view: MenuView, selectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1{
            APP.curFoldername = APP.curAccount!.folders![indexPath.row].name
            let messages = APP.messageStore.getAllMessage(APP.curFoldername)
            self.messages = messages
            self.tableView.reloadData()
            self.getNewMessages()
            self.title =  Utility.chineseFromEnglish(APP.curFoldername)
        }else{
            print(APP.curAccount!.username)
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
