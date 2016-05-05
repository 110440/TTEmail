//
//  EmailDetail2ViewController.swift
//  TT-Email
//
//  Created by tanson on 16/4/27.
//  Copyright © 2016年 tanson. All rights reserved.
//

import UIKit

private let size = UIScreen.mainScreen().bounds.size
private let topViewHeight:CGFloat = 100

class EmailDetailViewController: UIViewController ,UIWebViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.contentInset.bottom = 44
        }
    }
    
    lazy var topView:UIView = {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: 0))
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor(white: 0.8, alpha: 0.5).CGColor
        
        let titleFont = UIFont.systemFontOfSize(15)
        let HSpace:CGFloat = 10
        let VSpace:CGFloat = 10
        
        let titleLab = UILabel(frame: CGRect(x:HSpace, y: VSpace, width: size.width - 2 * HSpace, height: 0))
        titleLab.font = titleFont
        titleLab.numberOfLines = 2
        titleLab.text = self.message?.subject
        titleLab.sizeToFit()
        view.addSubview(titleLab)
        
        let displayNameFont = UIFont.systemFontOfSize(12)
        let titleLabHeight = self.message?.subject.heightForFont(titleFont , width:Float(size.width - 2 * HSpace ) )
        let y = CGFloat(Float(VSpace) + titleLabHeight! + 5)
        let text = "\(self.message!.displayName) 发至 我"
        
        
        let displayNameLab = UILabel(frame: CGRect(x: HSpace, y:y, width: size.width, height: 0) )
        displayNameLab.font = displayNameFont
        displayNameLab.textColor = UIColor.lightGrayColor()
        displayNameLab.text = text
        displayNameLab.sizeToFit()
        view.addSubview(displayNameLab)
        
        let displayNameLabHeight = text.heightForFont(displayNameFont, width: Float(size.width) )
        
        view.frame.size.height = y + CGFloat(displayNameLabHeight) + VSpace
        return view
    }()
    
    lazy var webView:UIWebView = {
        let h = self.topView.frame.size.height
        let view = UIWebView(frame:CGRect(x: 0, y: h, width:size.width, height:1))
        view.delegate = self
        view.scalesPageToFit = false
        return view
    }()
    
    var getHtmlOP:MCOIMAPBaseOperation?
    var isFinished = false
    var body:String!
    var message:EmailMessage?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.scrollView.addSubview(self.webView)
        self.scrollView.addSubview(self.topView)
        
        let uid = self.message!.uid
        
        self.getHtmlOP = APP.emailStore.fetchMessageHtmlBody(APP.curIMAPSession, userName:APP.curEmailAccount!.username, folerName: APP.curFoldername, uid: uid, completion: {[weak self] (error, body) in
            guard let wself = self else{return}
            dispatch_async(dispatch_get_main_queue()){
                if error == nil{
                    //print(body)
                    wself.body = body
                    wself.webView.loadHTMLString(body!, baseURL: nil)
                    wself.webView.hidden = true
                }
            }
        })
        
    }
    
    deinit{
        self.getHtmlOP?.cancel()
    }
    
    //MARK: webViewDelegate
    func webViewDidFinishLoad(webView: UIWebView) {
        
        //加载完成
        if self.isFinished {
            self.webView.hidden = false
            
            //计算 scrollView contentSize
            self.setWebViewFrame()
            let h = max(topViewHeight + self.webView.bounds.height, self.scrollView.bounds.size.height - 44)
            self.scrollView.contentSize = CGSize(width: size.width, height:h)
            return
        }
        
        //js获取body宽度，重新加载
        let bodyWidthStr = webView.stringByEvaluatingJavaScriptFromString("document.body.scrollWidth")
        let bodyWidth    = Float(bodyWidthStr!)
        
        let newHtml = self.htmlAdjustWithPageWidth(CGFloat(bodyWidth!), html: self.body)
        self.isFinished = true
        self.webView.loadHTMLString(newHtml, baseURL: nil)
        self.webView.hidden = false
    }
    
    //MARK:private
    private func setWebViewFrame(){
        var frame = self.webView.frame
        frame.size.height = 1
        self.webView.frame = frame
        let fittingSize = self.webView.sizeThatFits(CGSizeZero)
        self.webView.frame.size.height = fittingSize.height
    }
    
    private func htmlAdjustWithPageWidth(pageWidth:CGFloat,html:String)->String{
        let scale = (self.webView.bounds.size.width - 30) / pageWidth
        let str = html as NSString
        let stringForReplace = "<meta name=\"viewport\" content=\" initial-scale=\(scale), minimum-scale=0.1, maximum-scale=2.0, user-scalable=yes\"></head>"
        let retStr = str.stringByReplacingOccurrencesOfString("</head>", withString: stringForReplace)
        return retStr
    }

    //action
    @IBAction func flagTheMessage(sender: AnyObject) {
    }
    
    @IBAction func deleteTheMessage(sender: AnyObject) {
    }

    @IBAction func answerTheMessage(sender: AnyObject) {
    }
    
    @IBAction func moreOperation(sender: AnyObject) {
    }
}
