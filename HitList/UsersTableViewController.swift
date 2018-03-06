//
//  UsersTableViewController.swift
//  HitList
//
//  Created by Mykhailo Tymchyshyn on 2/20/18.
//  Copyright © 2018 Mykhailo Tymchyshyn. All rights reserved.
//

import UIKit
import FacebookLogin
import FBSDKCoreKit
import CoreData 

protocol FriendSelectionDelegate: class {
    func friendSelected(_ friend: User)
}

protocol ChatDelegate: class {
    func newMessage(from: User, message: String)
}

class UsersTableViewController: UITableViewController {
    
    weak var delegate: FriendSelectionDelegate?
    weak var chatDelegate: ChatDelegate?
    var fetchedResultsController: NSFetchedResultsController<User>!
    //MARK: Properties
    var messagesDelegate: UserSelectionDelegate? 
    
    //an array of users
    var friendsLogins = ["Mark", "Bill", "Gabe", "Elon", "Edward", "Jony", "Elliot", "Incognito", "Neighbor", "Roommate"]
    var defaultUserPassword = "qwerty12345"
 
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeFetchedResultsController()
        guard let sections = self.fetchedResultsController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[0]
        if sectionInfo.numberOfObjects < 10 {
            addUsersToADatabase()
        }
        initializeFetchedResultsController()
        splitViewController?.delegate = self

        DispatchQueue.global(qos: .background).async {
            while (true) {
                guard let user1 = self.fetchedResultsController?.object(at: IndexPath(row: 0, section: 0) ) else {
                    fatalError("No user")
                }
                self.chatDelegate?.newMessage(from: user1, message: "Hey, how are you ?")
                guard let user2 = self.fetchedResultsController?.object(at: IndexPath(row: 2, section: 0) ) else {
                    fatalError("No user")
                }
                self.chatDelegate?.newMessage(from: user2, message: "Miss me?")
                sleep(5)
            }
        }
        
    }

    var loginUsingAppLogin: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
        if FBSDKAccessToken.current() != nil {
            // User is logged in, use 'accessToken' here.
            FBSDKProfile.loadCurrentProfile { (profile, error) in
                if let user = CoreDataManager.shared.getUserWith(login: "\((profile?.firstName)!) \((profile?.lastName)!)") {
                    self.messagesDelegate?.userSelected( user )
                    self.title = profile?.firstName
                }
            }
        } else if loginUsingAppLogin {
            //
        } else {
            performSegue (withIdentifier: "SegueToLogIn", sender: nil)
        }
        if backgroundTask != UIBackgroundTaskInvalid {
            endBackgroundTask()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        registerBackgroundTask()
    }

    // MARK: - TableView data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let frc = fetchedResultsController {
            return frc.sections!.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.fetchedResultsController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        
        guard let userCell = cell as? UserTableViewCell else {
            fatalError("downcast failed")
        }
        guard let object = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        userCell.userName.text = object.login

        return userCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let user = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
            delegate?.friendSelected(user)
        if let detailViewController = delegate as? MessagesViewController {
            splitViewController?.showDetailViewController(detailViewController, sender: nil)
        }
    }

    @IBAction func goBack(segue: UIStoryboardSegue) {
        if let sourceSegue = segue.source as? SignInViewController {
            self.title = sourceSegue.loginTextField.text
            loginUsingAppLogin = true
            initializeFetchedResultsController()
            tableView.reloadData()
        }
    }
    
    @IBAction func logOutButton(_ sender: UIBarButtonItem) {
        LoginManager().logOut()
        messagesDelegate?.nullifiUser()
        performSegue(withIdentifier: "SegueToLogIn", sender: sender)
    }
    
    func initializeFetchedResultsController() {
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        let request: NSFetchRequest<User> = User.fetchRequest()
        let loginSort = NSSortDescriptor(key: "login", ascending: true)
        request.sortDescriptors = [loginSort]
        let moc = managedContext
        
        //with caching does not work right for some reason
        //I guess it does not take request change into account, hmm...
        //A: when i change something about request i have to invalidate my cache
       
        fetchedResultsController = NSFetchedResultsController<User>(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
        tableView.reloadData()
    }
    
    private func addUsersToADatabase() {
        for friendLogin in friendsLogins {
            CoreDataManager.shared.saveNewUser(login: friendLogin, email: "\(friendLogin)@gmail.com" , password: defaultUserPassword )
        }
    }
    
    //MARK: - Background Activities Thing
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            DispatchQueue.global(qos: .background).async {
                while (true) {
                    guard let user1 = self?.fetchedResultsController?.object(at: IndexPath(row: 0, section: 0) ) else {
                        fatalError("No user")
                    }
                    self?.chatDelegate?.newMessage(from: user1, message: "Hey, how are you ?")
                    guard let user2 = self?.fetchedResultsController?.object(at: IndexPath(row: 2, section: 0) ) else {
                        fatalError("No user")
                    }
                    self?.chatDelegate?.newMessage(from: user2, message: "Miss me?")
                    sleep(5)
                }
                }
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
  
}

extension UsersTableViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

