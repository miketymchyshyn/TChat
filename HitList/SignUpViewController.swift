//
//  SignUpViewController.swift
//  HitList
//
//  Created by Mykhailo Tymchyshyn on 2/21/18.
//  Copyright © 2018 Mykhailo Tymchyshyn. All rights reserved.
//

import UIKit
import CoreData

// TODO: inform user about incorrect input
class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    let unwindSegueIdentifier = "goBackToLoginFromSignUp"
    
    @IBOutlet weak var loginField: UITextField!    
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var signUpButtonOutlet: UIButton!
    @IBOutlet var textFieldOutlets: [UITextField]!
    
    //MARK: - Button Outlets
    @IBAction func signUpButton(_ sender: UIButton) {
        saveUser(login: loginField.text!, password: passwordField.text!, email: emailField.text! )
    }
   
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loginField.delegate = self
        passwordField.delegate = self
        confirmPassword.delegate = self
        emailField.delegate = self
        signUpButtonOutlet.isEnabled = false
        signUpButtonOutlet.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resignKeyboard)))
    }

    //MARK: - UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textInEveryTextFieldIsValid() {
            enableSignUpButton()
        } else {
            disableSignUpButton()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        // Do not add a line break
        return false
    }
   
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textInEveryTextFieldIsValid() {
            enableSignUpButton()
        } else {
            disableSignUpButton()
        }
        return true
    }
    
    //MARK: - Private Methods
    private func isLoginValid() -> Bool {
        if let loginLength = loginField.text?.count, loginLength >= minimalLoginLength {
            return true
        } else {
            return false
        }
    }
    
    private func passwordsMatch() -> Bool {
        if let passwordLength = passwordField.text?.count,  passwordLength > minimalPasswordLength {
            return passwordField.text == confirmPassword.text
        }
        return false
    }
    
    private func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: emailField.text )
    }
    
    ///Save user to database
    private func saveUser(login: String, password: String, email: String) {
        if CoreDataManager.shared.getUserWith(login: login) != nil {
            //if user already exists
            let alert = UIAlertController(title: "Sign Up Failed", message: "User already registred.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            CoreDataManager.shared.saveNewUser(login: login, email: email, password: password)
            performSegue(withIdentifier: "goBackToLoginFromSignUp", sender: self)
        }
    }
    private func disableSignUpButton(){
        signUpButtonOutlet.isEnabled = false
        signUpButtonOutlet.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    }
    
    private func enableSignUpButton(){
        signUpButtonOutlet.isEnabled = true
        signUpButtonOutlet.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
    }
    
    private func textInEveryTextFieldIsValid() -> Bool {
        let loginValid = self.isLoginValid()
        let passwordsMatch = self.passwordsMatch()
        let emailValid = self.isValidEmail()
        
        return loginValid && passwordsMatch && emailValid
    }
    
    @objc func resignKeyboard() {
        view.endEditing(true)
    }
}
