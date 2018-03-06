//
//  ViewController.swift
//  HitList
//
//  Created by Mykhailo Tymchyshyn on 2/19/18.
//  Copyright © 2018 Mykhailo Tymchyshyn. All rights reserved.
//

import UIKit
import CoreData

let constraintConstant: CGFloat = 80
let messageBubbleCornerRadius: CGFloat = 15
let messageBubbleBackgroundAlpha: CGFloat = 0.75

class MessagesViewController: UIViewController, UITextFieldDelegate, NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate {
    
    @IBOutlet weak var stackViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var aboutButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButtonOutlet: UIButton!
    
    @IBAction func sendButton(_ sender: UIButton) {
        if let message = textField.text {
            if !message.isEmpty {
                if user != nil && friend != nil {
                    saveNewLetter( from: user, to: friend , message: message )
                    textField.text = ""
                }
            }
        }
    }
    
    
    var fetchedResultsController: NSFetchedResultsController<Letter>!
    
    func initializeFetchedResultsController() {
        if user != nil && friend != nil {
            fetchedResultsController = CoreDataManager.shared.getFetchResultsControllerWithUserMessages(user1: user, user2: friend)
             fetchedResultsController.delegate = self
        }
    }

    
    var user : User! {
        didSet {
            initializeFetchedResultsController()
            tableView.reloadData()
        }
    }
    
    var friend : User! {
        didSet {
            initializeFetchedResultsController()
            title = friend.login
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "backgroundImage.jpg")!)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tableView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func dismissKeyboard(sender: UITapGestureRecognizer){
        textField.endEditing(true)
        textField.resignFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    var keyboardWillShowObserver: NSObjectProtocol?
    var keyboardWillHideObserver: NSObjectProtocol?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.endEditing(true)
        textField.resignFirstResponder()
        
        keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillShow , object: nil , queue: OperationQueue.main, using: { (notification)
            in
            let keyboardRect = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"]  as! CGRect
            let verticalDisplacemet = keyboardRect.size.height
            let keyboardAnimationDuration = notification.userInfo?["UIKeyboardAnimationDurationUserInfoKey"]
            self.animateStackViewBottomConstraint(to: verticalDisplacemet, in: keyboardAnimationDuration as! TimeInterval)
            self.view.layoutIfNeeded()
            
        })
        
        keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillHide, object: nil, queue: OperationQueue.main, using: { (notification)
            in
            let keyboardAnimationDuration = notification.userInfo?["UIKeyboardAnimationDurationUserInfoKey"]
            self.animateStackViewBottomConstraint(to: 6, in: keyboardAnimationDuration as! TimeInterval)
            self.view.layoutIfNeeded()
        })
        if let sections = fetchedResultsController?.sections {
            let sectionInfo = sections[0]
            if sectionInfo.numberOfObjects > 1 {
                tableView.scrollToRow(at: IndexPath(row: sectionInfo.numberOfObjects - 1, section: 0 ),
                                      at: UITableViewScrollPosition.bottom,
                                      animated: false)
            }
        }
        
    }
    
    private func animateStackViewBottomConstraint(to value: CGFloat, in duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: {
            self.stackViewBottomConstraint.constant = value
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//                NotificationCenter.default.removeObserver(keyboardWillShowObserver!)
//                NotificationCenter.default.removeObserver(keyboardWillHideObserver!)
            navigationController?.navigationBar.tintAdjustmentMode = .normal
            navigationController?.navigationBar.tintAdjustmentMode = .automatic
    }
    
    private func saveNewLetter(from: User, to: User, message: String) {       
        if user != nil {
            CoreDataManager.shared.saveNewLetter(from: from, to: to, message: message, date: Date())
            if from != user {
            NotificationCenter.default.post( name: NSNotification.Name.NewMessage, object: self, userInfo: ["message": message, "sender": from.login as Any, "to": user.login as Any] )
            }
        }
    }
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let settingsVC = segue.destination as? SettingsViewController {
           settingsVC.user = user
        }
    }
    
    
    //MARK: - UITextFieldDelegate
    var keyboardObserver : NSObjectProtocol?
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        keyboardObserver = NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidChange, object: nil, queue: OperationQueue.main, using: {
            (notification)
            in
            let textField = notification.object as? UITextField
            if let input = textField?.text {
                if input.isEmpty {
                    self.sendButtonOutlet.isEnabled = false
                } else {
                    self.sendButtonOutlet.isEnabled = true
                }
            }
        })
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Do not clear text field after keyboard hides.
    }
    
    //MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        guard let sections = self.fetchedResultsController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[0]
        let numOfMessages = sectionInfo.numberOfObjects
        guard let letter = self.fetchedResultsController?.object(at: IndexPath(row: numOfMessages - 1, section:0)) else {
            fatalError(" ")
        }
        if letter.from == user {
            // Scroll to the last row if message comes from user.
            if let sections = fetchedResultsController?.sections {
                let sectionInfo = sections[0]
                if sectionInfo.numberOfObjects > 1 {
                    tableView.scrollToRow(at: IndexPath(row: numOfMessages - 1, section: 0 ),
                                          at: UITableViewScrollPosition.bottom,
                                          animated: true)
                }
            }
        } else if letter.from == friend {
            // Scroll to the last row if message comes form fried and last row of table view is visible.
            if (tableView.indexPathsForVisibleRows?.contains(IndexPath(row: numOfMessages - 2, section: 0 )))! {
                if let sections = fetchedResultsController?.sections {
                    let sectionInfo = sections[0]
                    if sectionInfo.numberOfObjects > 1 {
                        tableView.scrollToRow(at: IndexPath(row: numOfMessages - 1, section: 0 ),
                                              at: UITableViewScrollPosition.bottom,
                                              animated: true)
                    }
                }

            }
        }
    }
}

// MARK: - UITableViewDataSource
extension MessagesViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        guard let messageCell = cell as? MessageTableViewCell else {
            fatalError("downcast failed...")
        }
        messageCell.backgroundColor = UIColor.clear
        messageCell.messageBackground.layer.cornerRadius = messageBubbleCornerRadius
        messageCell.messageBackground.alpha = messageBubbleBackgroundAlpha
        
        guard let letter = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        messageCell.messageTextLabel.text = letter.message
        
        if letter.from == user {
            messageCell.messageBackground.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
            messageCell.messageTextLabel.textAlignment = .right
            messageCell.leadingForBackground.constant = constraintConstant
            messageCell.textLeading.constant = constraintConstant
            messageCell.trailingForBackground.constant = 0
            messageCell.textTrailing.constant = 0
        } else if letter.from == friend {
            messageCell.messageBackground.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            messageCell.messageTextLabel.textAlignment = .left
            messageCell.trailingForBackground.constant = constraintConstant
            messageCell.textTrailing.constant = constraintConstant
            messageCell.leadingForBackground.constant = 0
            messageCell.textLeading.constant = 0
        } else {
            print("message recieved while no user logged in.")
        }
        return messageCell
    }
    
}


extension MessagesViewController: FriendSelectionDelegate, UserSelectionDelegate {
    func userSelected(_ user: User) {
        self.user = user
    }
    
    func nullifiUser() {
        self.user = nil
    }
    
    func friendSelected(_ friend: User) {
        self.friend = friend
    }
}

extension MessagesViewController: ChatDelegate {
    func newMessage(from: User, message: String) {
        if user != nil {
            saveNewLetter(from: from, to: user, message: message)
        }
    }
}

// MARK: - Custom notification
extension Notification.Name {
    static let NewMessage = Notification.Name("NewMessage")
}
