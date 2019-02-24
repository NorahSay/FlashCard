//
//  ViewController.swift
//  Flash Chat
//
//  Created by Angela Yu on 29/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Declare instance variables here
    var messageArray : [Message] = [Message]()
    var text : String = ""
    var images : UIImage?
    
    // We've pre-linked the IBOutlets
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextView: UITextView!
    @IBOutlet var messageTableView: UITableView!
    @IBOutlet weak var cameraButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        sendButton.isEnabled = false
        cameraButton.imageView?.contentMode = .scaleAspectFit
        
        //TODO: Set yourself as the delegate and datasource here:
        messageTableView.delegate = self
        messageTableView.dataSource = self
        
        //TODO: Set yourself as the delegate of the text field here:
        messageTextView.delegate = self
        
        //TODO: Set the tapGesture here:
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dimissKeyboard(_:)))
        self.view.addGestureRecognizer(tap)
        

        //TODO: Register your MessageCell.xib file here:
        messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
        messageTableView.register(UINib(nibName: "SentMessageTableViewCell", bundle: nil), forCellReuseIdentifier: "SentMessageTableViewCell")
        
        configureTableView()
        retrieveMessages()
        
        //TableViewStyle
        messageTableView.separatorStyle = .none
        
        //messageTextView Style
        messageTextView.clipsToBounds = true
        messageTextView.layer.cornerRadius = 10.0
        messageTextView.text = "Enter Your Message"
        messageTextView.textColor = UIColor.lightGray
        
    }

    ///////////////////////////////////////////
    
    //MARK: - TableView DataSource Methods
    
    
    
    //TODO: Declare cellForRowAtIndexPath here:
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messages = messageArray[(indexPath as NSIndexPath).row]
        
        if messages.sender == (Auth.auth().currentUser?.email)! {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SentMessageTableViewCell", for: indexPath) as! SentMessageTableViewCell
            cell.selectionStyle = .none
            cell.messageBody.text = messages.messageBody
            //cell.senderUsername.text = "Me"
            cell.avatarImageView.image = UIImage(named: "MH2")
            //cell.avatarImageView.backgroundColor = UIColor.flatMint()
            cell.messageBackground.backgroundColor = UIColor.flatSkyBlue()
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
            cell.selectionStyle = .none
            cell.messageBody.text = messages.messageBody
            cell.senderUsername.text = messages.sender
            cell.avatarImageView.image = UIImage(named: "MH")
            //cell.avatarImageView.backgroundColor = UIColor.flatWatermelon()
            cell.messageBackground.backgroundColor = UIColor.flatGray()
            
            return cell
        }
        
    }
    
    
    //TODO: Declare numberOfRowsInSection here:
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageArray.count
    }
    
    //TODO: Declare configureTableView here:
    func configureTableView() {
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTableView.estimatedRowHeight = 120.0
    }
    
    
    ///////////////////////////////////////////
    
    //MARK:- TextView Delegate Methods
    

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            var newText = textView.text! as NSString
            newText = newText.replacingCharacters(in: range, with: text) as NSString

            //Enable or diable send button
            if newText == "" {
                sendButton.isEnabled = false
            } else {
                sendButton.isEnabled = true
            }
            return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification , object: nil)
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Enter Your Message"
            textView.textColor = UIColor.lightGray
        }
    }
    
    //TODO: Declare textFieldDidEndEditing here:
    
    @objc func dimissKeyboard(_ sender: UIGestureRecognizer) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification , object: nil)
        self.view.endEditing(true)
        
    }
    

    // MARK - Handle Keyboards
    
    @objc func keyboardWillShow(notification: NSNotification)    {
        
        if let userInfo = notification.userInfo as? Dictionary<String, Any> {
            let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: curveRaw.uintValue)
            
            
            UIView.animate(withDuration: Double(truncating: duration), delay: 0, options: animationCurve, animations: {
                self.heightConstraint.constant = keyboardHeight + 50
                self.scrollToLast()
                self.view.layoutIfNeeded()
            }, completion: nil)
            
        }
        
    }
    
    @objc func keyboardWillHide(notification : NSNotification) {
        
        if let userInfo = notification.userInfo as? Dictionary<String, Any> {
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: curveRaw.uintValue)
            
            messageTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
            UIView.animate(withDuration: Double(truncating: duration), delay: 0, options: animationCurve, animations: {
                self.heightConstraint.constant = 50
                self.scrollToLast()
                self.view.layoutIfNeeded()
                
            }, completion: nil)
            
        }
    }
    
    
    
    
    
    
    ///////////////////////////////////////////
    
    
    //MARK: - Send & Recieve from Firebase
    

    @IBAction func sendPressed(_ sender: AnyObject) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification , object: nil)
        
        //TODO: Send the message to Firebase and save it in our database
        sendButton.isEnabled = false
        
        let messagesDB = Database.database().reference().child("Message")
        let messageDictionary = ["Sender" : Auth.auth().currentUser?.email,
                                 "MessageBody" : messageTextView.text!] as [String : Any]
        messagesDB.childByAutoId().setValue(messageDictionary) {
            (error, reference) in
            if error != nil {
                print(error!)
            } else {
                print("message saved")
                self.messageTextView.text = ""
            }
        }
        
    }
    
    //TODO: Create the retrieveMessages method here:
    func retrieveMessages() {
        let messageDB = Database.database().reference().child("Message")
        messageDB.observe(.childAdded) { (snapshot) in
            let snapshotValue = snapshot.value as! Dictionary<String, String>
            let text = snapshotValue["MessageBody"]!
            let sender = snapshotValue["Sender"]!
            
            let message = Message()
            message.messageBody = text
            message.sender = sender
            self.messageArray.append(message)
            
            self.configureTableView()
            self.messageTableView.reloadData()
            
            self.scrollToLast()
            
        }
    }

    func scrollToLast() {
        if self.messageArray.count - 1 > 0 {
            self.messageTableView.scrollToRow(at: IndexPath(row: self.messageArray.count - 1, section: 0), at: .bottom, animated: false)
        }
    }
    
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        
        //TODO: Log out the user and send them back to WelcomeViewController
        do {
            try Auth.auth().signOut()
            if let navigationController = navigationController {
                navigationController.popToRootViewController(animated: true)
            }
        } catch {
            print("error, there was a problem signing out.")
        }
    }
    
    
    // MARK: Camera button
    @IBAction func cameraPressed(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            images = image
            dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }


}




