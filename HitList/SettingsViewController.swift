//
//  SettingsViewController.swift
//  HitList
//
//  Created by Mykhailo Tymchyshyn on 2/28/18.
//  Copyright © 2018 Mykhailo Tymchyshyn. All rights reserved.
//

import UIKit
import CoreData

class SettingsViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userLogin.text = user.login
    }
    
    var user: User!
    @IBOutlet weak var userLogin: UILabel!
    @IBOutlet weak var oldPasswordField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!
    @IBAction func backButton(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func changePassword(_ sender: UIButton) {
        let managedContext = CoreDataManager.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<User>(entityName: "User")
        fetchRequest.predicate = NSPredicate(format: "login = %@", user.login!)
        do {
            let users = try managedContext.fetch(fetchRequest)
            if users.count == 1 {
                if let oldPassword = users.first?.password, oldPasswordField.text == oldPassword {
                    if let newPassword = newPasswordField.text, newPassword.count >= minimalPasswordLength {
                        users.first?.password = newPassword
                        do {
                            try managedContext.save()
                            showAlert()
                        } catch let error as NSError {
                            print("Could not save. \(error), \(error.userInfo)")
                        }
                    } else {
                        //Present alert that new password is not long ernough
                        let alert = UIAlertController(title: "Bad Password", message: "New password is too short. Should be at least five characters.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        
                        present(alert, animated: true, completion: nil)
                    }
                } else {
                    //Present alert that user password is incorrect
                    let alert = UIAlertController(title: "Incorrect Password", message: "Wrong account password", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    
                    present(alert, animated: true, completion: nil)
                }
            } else {
                fatalError("Multiple users with the same login in CoreData database.")
            }
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }


    // MARK: - Private Methods
    func showAlert() {
        let alertController = UIAlertController(title: "Password change successful", message: "", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) -> Void in
            self.performSegue(withIdentifier: "goBackToUsersSegue", sender: self)
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion:nil)
    }
}
