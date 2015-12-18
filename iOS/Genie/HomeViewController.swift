//
//  HomeViewController.swift
//  Genie
//
//  Created by Krishna Chaitanya Aluru on 8/25/15.
//  Copyright © 2015 genie. All rights reserved.
//

import UIKit
import Firebase
import VerifyIosSdk
import SVPullToRefresh
import SVProgressHUD


class HomeViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var checkAttachmentTimer: NSTimer!
    
    let imagePicker = UIImagePickerController()
    var currentAttachment: UIImage?
    var defaultLeftButton: UIButton!
    
    var user: FAuthData?
    
    var ref: Firebase!
    var messagesRef: Firebase!
    
    var messages = [Message]()
    var mobileNumber: String!
    
    var getMessagesHandle: UInt!
    
    var incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    var outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor(red: (27/255.0), green: (165/255.0), blue: (221/255.0), alpha: 1.0))
    
    var pizzaHelp: UILabel!
    var furnitureHelp: UILabel!
    var ticketHelp: UILabel!
    var helperFoot: UILabel!
    var firstMessageRead: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        imagePicker.delegate = self
        print("Home")
        
        self.firstMessageRead = true
        
        self.ref = Firebase(url:"https://getgenie.firebaseio.com/")
        
        self.user = self.ref.authData
        self.senderId = self.user?.uid
        self.senderDisplayName = "not_set"
        
        let firstNameRef = ref.childByAppendingPath("users/" + senderId + "/first_name")
        firstNameRef.observeEventType(.Value, withBlock: { snapshot in
            self.senderDisplayName = snapshot.value as! String
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        let mobileNumberRef = ref.childByAppendingPath("users/" + senderId + "/mobile_number")
        mobileNumberRef.observeEventType(.Value, withBlock: { snapshot in
            self.mobileNumber = snapshot.value as! String
            }, withCancelBlock: { error in
                print(error.description)
        })
        
        
        // Setting up Input Bar -----------------------------------------------------------------
        
        if let toolbar = inputToolbar {
            if let conview = toolbar.contentView {
                conview.backgroundColor = UIColor.whiteColor()
                if let texview = conview.textView {
                    texview.layer.borderWidth = 0
                    texview.placeHolder = "Type a message"
                    texview.font = UIFont(name: "SFUIText-Regular", size: 15.0)
                }
                if let rightbarbutton = conview.rightBarButtonItem {
                    rightbarbutton.setTitle("", forState: UIControlState.Normal)
                }
                self.defaultLeftButton = conview.leftBarButtonItem
                let sendImage = UIImage(named: "lamp.png")
                let sendButton: UIButton = UIButton(type: UIButtonType.Custom)
                sendButton.setImage(sendImage, forState: UIControlState.Normal)
                conview.rightBarButtonItem = sendButton
            }
        }
        
        automaticallyScrollsToMostRecentMessage = true
        
        // --------------------------------------------------------------------------------------
        
        
        // Helper Labels ------------------------------------------------------------------------
        
        self.pizzaHelp = UILabel()
        self.pizzaHelp.translatesAutoresizingMaskIntoConstraints = false
        self.pizzaHelp.numberOfLines = 0
        self.pizzaHelp.font = UIFont(name: "SFUIText-Regular", size: 15.0)
        self.pizzaHelp.textAlignment = NSTextAlignment.Center
        self.pizzaHelp.textColor = UIColor.lightGrayColor()
        self.pizzaHelp.text = "Can you order me some pizza?"
        self.pizzaHelp.sizeToFit()
        self.view.addSubview(pizzaHelp)
        let pizzaHelpxCenterConstraint = NSLayoutConstraint(item: self.pizzaHelp, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
        let pizzaHelpyCenterConstraint = NSLayoutConstraint(item: self.pizzaHelp, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1, constant: 0)
        let pizzaHelpWidthConstraint = NSLayoutConstraint(item: self.pizzaHelp, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant:self.pizzaHelp.frame.width)
        let pizzaHelpHeightConstraint = NSLayoutConstraint(item: self.pizzaHelp, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant:self.pizzaHelp.frame.height)
        self.view.addConstraints([pizzaHelpHeightConstraint, pizzaHelpWidthConstraint, pizzaHelpxCenterConstraint, pizzaHelpyCenterConstraint])
        self.view.insertSubview(self.pizzaHelp, belowSubview: (inputToolbar)!)
        
        self.furnitureHelp = UILabel()
        self.furnitureHelp.translatesAutoresizingMaskIntoConstraints = false
        self.furnitureHelp.numberOfLines = 0
        self.furnitureHelp.font = UIFont(name: "SFUIText-Regular", size: 15.0)
        self.furnitureHelp.textAlignment = NSTextAlignment.Center
        self.furnitureHelp.textColor = UIColor.lightGrayColor()
        self.furnitureHelp.text = "Where can I find furniture for my house?"
        self.furnitureHelp.sizeToFit()
        self.view.addSubview(self.furnitureHelp)
        let furnitureHelpxCenterConstraint = NSLayoutConstraint(item: self.furnitureHelp, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
        let furnitureHelpWidthConstraint = NSLayoutConstraint(item: self.furnitureHelp, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant:self.furnitureHelp.frame.width)
        let furnitureHelpHeightConstraint = NSLayoutConstraint(item: self.furnitureHelp, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant:self.furnitureHelp.frame.height)
        let furnitureHelpyConstraint = NSLayoutConstraint(item: self.furnitureHelp, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.pizzaHelp, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: -10)
        self.view.addConstraints([furnitureHelpxCenterConstraint, furnitureHelpyConstraint, furnitureHelpHeightConstraint, furnitureHelpWidthConstraint])
        self.view.insertSubview(self.furnitureHelp, belowSubview: (inputToolbar)!)
        
        self.ticketHelp = UILabel()
        self.ticketHelp.translatesAutoresizingMaskIntoConstraints = false
        self.ticketHelp.numberOfLines = 0
        self.ticketHelp.font = UIFont(name: "SFUIText-Regular", size: 15.0)
        self.ticketHelp.textAlignment = NSTextAlignment.Center
        self.ticketHelp.textColor = UIColor.lightGrayColor()
        self.ticketHelp.text = "I would like to book movie tickets!"
        self.ticketHelp.sizeToFit()
        self.view.addSubview(self.ticketHelp)
        let ticketHelpxCenterConstraint = NSLayoutConstraint(item: self.ticketHelp, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
        let ticketHelpWidthConstraint = NSLayoutConstraint(item: self.ticketHelp, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant:self.ticketHelp.frame.width)
        let ticketHelpHeightConstraint = NSLayoutConstraint(item: self.ticketHelp, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant:self.ticketHelp.frame.height)
        let ticketHelpyConstraint = NSLayoutConstraint(item: self.ticketHelp, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.pizzaHelp, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 10)
        self.view.addConstraints([ticketHelpxCenterConstraint, ticketHelpyConstraint, ticketHelpHeightConstraint, ticketHelpWidthConstraint])
        self.view.insertSubview(self.ticketHelp, belowSubview: (inputToolbar)!)
        
        self.helperFoot = UILabel()
        self.helperFoot.translatesAutoresizingMaskIntoConstraints = false
        self.helperFoot.numberOfLines = 0
        self.helperFoot.lineBreakMode = NSLineBreakMode.ByWordWrapping
        self.helperFoot.font = UIFont(name: "SFUIText-Medium", size: 15.5)
        self.helperFoot.textAlignment = NSTextAlignment.Center
        let mainString = "Find more here!"
        let stringHighlight = "here"
        let stringNormal = "Find more "
        let stringExc = "!"
        let rangeHighlight = (mainString as NSString).rangeOfString(stringHighlight)
        let rangeNormal = (mainString as NSString).rangeOfString(stringNormal)
        let rangeExc = (mainString as NSString).rangeOfString(stringExc)
        let attributedString = NSMutableAttributedString(string:mainString)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 52/255.0, green: 73/255.0, blue: 94/255.0, alpha: 1.0), range: rangeNormal)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 52/255.0, green: 73/255.0, blue: 94/255.0, alpha: 1.0), range: rangeExc)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 27/255.0, green: 165/255.0, blue: 221/255.0, alpha: 1.0), range: rangeHighlight)
        self.helperFoot.attributedText = attributedString
        self.helperFoot.sizeToFit()
        self.helperFoot.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        self.view.addSubview(self.helperFoot)
        let helperFootxCenterConstraint = NSLayoutConstraint(item: self.helperFoot, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
        let helperFootWidthConstraint = NSLayoutConstraint(item: self.helperFoot, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant:250)
        let helperFootyConstraint = NSLayoutConstraint(item: self.helperFoot, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.pizzaHelp, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 40)
        self.view.addConstraints([helperFootxCenterConstraint, helperFootWidthConstraint, helperFootyConstraint])
        self.view.insertSubview(self.helperFoot, belowSubview: (inputToolbar)!)

        helperFoot.hidden = true
        pizzaHelp.hidden = true
        furnitureHelp.hidden = true
        ticketHelp.hidden = true
        
        // --------------------------------------------------------------------------------------
        

        // Handling Navigation Bar --------------------------------------------------------------
        
        self.navigationController?.navigationBar.hidden = true        
        
        // --------------------------------------------------------------------------------------
        
        
        // Removing avatars ---------------------------------------------------------------------
        
        self.collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
        self.collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
        
        // --------------------------------------------------------------------------------------
        
        
        // Adding delete action -----------------------------------------------------------------
        
        UIMenuController.sharedMenuController().menuItems = [UIMenuItem(title: "Delete", action: "deleteMessage:")]
        JSQMessagesCollectionViewCell.registerMenuAction("deleteMessage:")
        
        // --------------------------------------------------------------------------------------
        
        // Scroll to top to get Earlier Messages ------------------------------------------------

        
        self.collectionView!.addPullToRefreshWithActionHandler({ () -> Void in
            self.loadMore()
        }, position: UInt(SVPullToRefreshPositionTop))
        
        
            
        // --------------------------------------------------------------------------------------
        
        
        // Dismiss keyboard on tap --------------------------------------------------------------
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        // --------------------------------------------------------------------------------------
        
        self.checkAttachmentTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("checkAttachment"), userInfo: nil, repeats: true)
        
        setupFirebase()

    }
    
    // Load Earlier Messages --------------------------------------------------------------------
    func loadMore(){
        print("Loading earlier messages")
        
        self.collectionView!.collectionViewLayout.springinessEnabled = false
        self.collectionView!.pullToRefreshView.startAnimating()
        var counter = 0
        
        //Disable Automatic Scrolling -----------------------------------------------------------
        automaticallyScrollsToMostRecentMessage = false
        
        let lastMsg = messages[0]
        
        self.messagesRef.queryOrderedByChild("timestamp").queryEndingAtValue(lastMsg.date().timeIntervalSince1970 * 1000 - 1).queryLimitedToLast(5).observeEventType(FEventType.ChildAdded, withBlock: {
            (snapshot) in
            if snapshot != nil && snapshot.key != "serviced" { 
                let messageId = snapshot.key
                let text = snapshot.value["text"] as? String
                let timestamp = snapshot.value["timestamp"] as? NSTimeInterval
                let date = NSDate(timeIntervalSince1970: timestamp!/1000)
                let sentByUser = snapshot.value["sent_by_user"] as! Bool
                let deletedByUser = snapshot.value["deleted_by_user"] as! Bool
                let isMediaMessage = snapshot.value["is_media_message"] as! Bool
                var sender = "notUser"
                if sentByUser == true {
                    sender = self.senderId
                }
                if !deletedByUser {
                    var message: Message!
                    if isMediaMessage {
                        let encodedString = snapshot.value["media"] as? String
                        if let encoding = encodedString {
                            let imageData = NSData(base64EncodedString: encoding, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                            let photoItem = JSQPhotoMediaItem(image: UIImage(data: imageData!))
                            message = Message(messageId: messageId, text: text, sentByUser: sentByUser, senderId: sender, senderDisplayName: self.senderDisplayName, date: date, isMediaMessage: isMediaMessage, media: photoItem)
                        }
                        else {
                            print("Could not attach photo")
                            message = Message(messageId: messageId, text: text, sentByUser: sentByUser, senderId: sender, senderDisplayName: self.senderDisplayName, date: date, isMediaMessage: isMediaMessage, media: nil)
                        }
                    }
                    else {
                        message = Message(messageId: messageId, text: text, sentByUser: sentByUser, senderId: sender, senderDisplayName: self.senderDisplayName, date: date, isMediaMessage: isMediaMessage, media: nil)
                    }
                    self.messages.insert(message, atIndex: counter)
                    counter = counter + 1
                }
            
            }
            self.finishReceivingMessage()
            
        })
        
        self.finishReceivingMessageAnimated(false)
        self.collectionView!.pullToRefreshView.stopAnimating()
        self.collectionView!.layoutIfNeeded()
        self.collectionView!.reloadData()
    }
    // ------------------------------------------------------------------------------------------
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Bubble springiness factor ------------------------------------------------------------
        
        collectionView!.collectionViewLayout.springinessEnabled = false
        
        // --------------------------------------------------------------------------------------
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.checkAttachmentTimer.invalidate()
    }
    
    func checkAttachment()
    {
        if self.currentAttachment != nil {
            self.inputToolbar?.contentView?.rightBarButtonItem?.enabled = true
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        if let pickedImage = image as? UIImage {
            self.currentAttachment = pickedImage
            if let toolbar = inputToolbar {
                if let conview = toolbar.contentView {
                    conview.leftBarButtonItem?.contentMode = .ScaleAspectFill
                    let attachButton: UIButton = UIButton(type: UIButtonType.Custom)
                    attachButton.setImage(pickedImage, forState: UIControlState.Normal)
                    self.defaultLeftButton = conview.leftBarButtonItem
                    conview.leftBarButtonItem = attachButton
                }
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func setupFirebase() {
        self.messagesRef = ref.childByAppendingPath("messages/" + self.senderId)
        
        if self.messages.count == 0 {
            self.pizzaHelp.hidden = false
            self.furnitureHelp.hidden = false
            self.ticketHelp.hidden = false
            self.helperFoot.hidden = false
        }
        
        self.collectionView!.collectionViewLayout.springinessEnabled = false

        self.getMessagesHandle = self.messagesRef.queryLimitedToLast(5).observeEventType(FEventType.ChildAdded, withBlock: {
            (snapshot) in
            if snapshot.key != "serviced" {
                
                let messageId = snapshot.key
                let text = snapshot.value["text"] as! String
                let timestamp = snapshot.value["timestamp"] as! NSTimeInterval
                let date = NSDate(timeIntervalSince1970: timestamp/1000)
                let sentByUser = snapshot.value["sent_by_user"] as! Bool
                let deletedByUser = snapshot.value["deleted_by_user"] as! Bool
                let isMediaMessage = snapshot.value["is_media_message"] as! Bool
                
                var sender = "not_user"
                
                if !sentByUser && !self.firstMessageRead! {
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.firstMessageRead = false
                }
                else {
                    sender = self.senderId
                }
                
                if !deletedByUser {
                    var message: Message!
                    if isMediaMessage {
                        let encodedString = snapshot.value["media"] as? String
                        if let encoding = encodedString {
                            let imageData = NSData(base64EncodedString: encoding, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                            let photoItem = JSQPhotoMediaItem(image: UIImage(data: imageData!))
                            message = Message(messageId: messageId, text: text, sentByUser: sentByUser, senderId: sender, senderDisplayName: self.senderDisplayName, date: date, isMediaMessage: isMediaMessage, media: photoItem)
                        }
                        else {
                            print("Could not attach photo")
                            message = Message(messageId: messageId, text: text, sentByUser: sentByUser, senderId: sender, senderDisplayName: self.senderDisplayName, date: date, isMediaMessage: isMediaMessage, media: nil)
                        }
                    }
                    else {
                        message = Message(messageId: messageId, text: text, sentByUser: sentByUser, senderId: sender, senderDisplayName: self.senderDisplayName, date: date, isMediaMessage: isMediaMessage, media: nil)
                    }
                    self.messages.append(message)
                    let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
                    
                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Background) {
                        if settings!.types == .None {
                            let ac = UIAlertController(title: "Can't schedule", message: "Either we don't have permission to schedule notifications, or we haven't asked yet.", preferredStyle: .Alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                            self.presentViewController(ac, animated: true, completion: nil)
                            return
                        }
                        
                        let notification = UILocalNotification()
                        notification.fireDate = NSDate(timeIntervalSinceNow: 1)
                        notification.alertBody = message.text()
                        notification.soundName = UILocalNotificationDefaultSoundName
                        UIApplication.sharedApplication().scheduleLocalNotification(notification)
                        print(message.text())
                    }
                }
                
                if self.messages.count > 0 {
                    self.pizzaHelp.hidden = true
                    self.furnitureHelp.hidden = true
                    self.ticketHelp.hidden = true
                    self.helperFoot.hidden = true
                }
                
                self.finishReceivingMessage()
            }
        })
//        self.collectionView!.collectionViewLayout.springinessEnabled = true
    }

    func sendMessage(text: String!) {
        if let attachment = self.currentAttachment {
            let imageData = UIImageJPEGRepresentation(attachment, 0.5)
            let imageString = imageData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
            
            self.messagesRef.childByAutoId().setValue([
                "text": text,
                "timestamp": FirebaseServerValue.timestamp(),
                "sent_by_user": true,
                "deleted_by_user": false,
                "is_media_message": true,
                "media": imageString
                ])
        }
        else {
            self.messagesRef.childByAutoId().setValue([
                "text": text,
                "timestamp": FirebaseServerValue.timestamp(),
                "sent_by_user": true,
                "deleted_by_user": false,
                "is_media_message": false
                ])
        }
        var isServiced: UInt!
        self.messagesRef.observeEventType(.Value, withBlock: { snapshot in
             isServiced = snapshot.value["serviced"] as! UInt
            }, withCancelBlock: { error in
                print(error.description)
        })
        if isServiced != nil {
            if isServiced == 1 {
                self.messagesRef.updateChildValues([
                    "serviced": 0
                    ])
            }
        }
        else {
            self.messagesRef.updateChildValues([
                    "serviced": 0
                ])
        }
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        if self.currentAttachment != nil {
            if text.isEmpty {
                sendMessage(text)
                self.finishSendingMessage()
                self.currentAttachment = nil
                if let toolbar = inputToolbar {
                    if let conview = toolbar.contentView {
                        conview.leftBarButtonItem = self.defaultLeftButton
                    }
                }
            }
            else {
                sendMessage("")
                self.finishSendingMessage()
                self.currentAttachment = nil
                if let toolbar = inputToolbar {
                    if let conview = toolbar.contentView {
                        conview.leftBarButtonItem = self.defaultLeftButton
                    }
                }
                sendMessage(text)
                self.finishSendingMessage()
            }
        }
        else {
            self.sendMessage(text)
            self.finishSendingMessage()
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .PhotoLibrary
        
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return self.messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = self.messages[indexPath.item]
        
        if message.sentByUser() == true {
            return self.outgoingBubble
        }
        
        return self.incomingBubble
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if (indexPath.item % 3 == 0) {
            let message = self.messages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date())
        }
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return 20.0
        }
        return 0.0
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 5.0
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.sentByUser() == true {
            cell.textView?.textColor = UIColor.whiteColor()
            cell.textView?.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
        } else {
            cell.textView?.textColor = UIColor.blackColor()
            cell.textView?.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.blackColor(),
                NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
        }

        return cell
    }
    
    // Delete action ----------------------------------------------------------------------
    
    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        if action == "deleteMessage:" {
            return true
        }
        return super.collectionView(collectionView, canPerformAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    
    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        if action == "deleteMessage:" {
            deleteMessage(collectionView, indexPath: indexPath)
        }
        super.collectionView(collectionView, performAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    
    func deleteMessage(collectionView: UICollectionView, indexPath: NSIndexPath) {
        let messageKey = self.messages[indexPath.item].messageId()
        let updateMessageRef = self.messagesRef.childByAppendingPath("/" + messageKey)
        updateMessageRef.updateChildValues([
            "deleted_by_user": true
            ])
        
        self.messages.removeAtIndex(indexPath.item)
        collectionView.deleteItemsAtIndexPaths([indexPath])

        if self.messages.count == 0 {
            self.pizzaHelp.hidden = false
            self.furnitureHelp.hidden = false
            self.ticketHelp.hidden = false
            self.helperFoot.hidden = false
        }
    }
    
    // --------------------------------------------------------------------------------------
    
    func logout(sender: UIBarButtonItem) {
        ref.removeObserverWithHandle(getMessagesHandle)
        ref.unauth()
        print("logged out user")
        performSegueWithIdentifier("LOGOUT", sender: self)
        
        VerifyClient.logoutUser(countryCode: "US", number: self.mobileNumber, completionBlock: { error in
            if let error = error {
                // unable to logout user
                print("could not logout nexmo : ", error)
            }
            
            print("logged out nexmo user")
        })
    }
    
    // Dismissing Keyboard ------------------------------------------------------------------
    
    // Dismiss keyboard on pressing the return key
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    // Dismiss the keyboard when tap is recognized
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // --------------------------------------------------------------------------------------
    
    
    // Orientation fixed to Portrait --------------------------------------------------------
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        return UIInterfaceOrientation.Portrait
    }
    
    // --------------------------------------------------------------------------------------

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
