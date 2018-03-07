//
//  SignInViewController.swift
//  HitList
//
//  Created by Mykhailo Tymchyshyn on 2/21/18.
//  Copyright © 2018 Mykhailo Tymchyshyn. All rights reserved.
//

import UIKit
import FacebookLogin
import FBSDKCoreKit
import CoreData

let containerCornerRadius: CGFloat = 15
let minimalLoginLength = 5
let minimalPasswordLength = 5

protocol UserSelectionDelegate: class {
    func userSelected(_ user: User)
    func nullifiUser()
}


//TODO: Add animation that shakes the text field and makes it red to indicate to the user that he entered an incorrect password.
class SignInViewController: UIViewController, LoginButtonDelegate, UITextFieldDelegate {

    @IBOutlet weak var containerForFields: UIView!
    @IBOutlet weak var logoImage: UIImageView!
    ///logInButton is the same thing as continueButton
    @IBOutlet weak var logInButtonOutlet: UIButton!
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signUpButtonOutlet: UIButton!
    @IBOutlet weak var viewForFacebookButton: UIView!
    
    
    @IBOutlet weak var constraintToTop: NSLayoutConstraint!
    @IBOutlet weak var constraintToBottom: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    private var messagesDelegate: UserSelectionDelegate? 
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loginTextField.delegate = self
        passwordTextField.delegate = self
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        let messagesVC = appDelegate.splitViewDetail
        messagesDelegate = messagesVC

        let loginButton = LoginButton( readPermissions: [ .publicProfile, .email] )
        loginButton.center = CGPoint(x: viewForFacebookButton.bounds.midX, y: viewForFacebookButton.bounds.midY )
        loginButton.delegate = self
        
        viewForFacebookButton.addSubview(loginButton)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(resignKeyboard)))
        
        containerForFields.layer.cornerRadius = containerCornerRadius
        viewForFacebookButton.backgroundColor = viewForFacebookButton.superview?.backgroundColor
        
        logoImage.layer.cornerRadius = logoImage.bounds.maxX / 2
        logoImage.clipsToBounds = true
    }

    //MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let loginLength = loginTextField.text?.count, loginLength >= minimalLoginLength, let passwordLength = passwordTextField.text?.count, passwordLength >= minimalPasswordLength {
            enableContinueButton()
        } else {
            disableContinueButton()
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
            if let loginLength = loginTextField.text?.count, loginLength >= minimalLoginLength {
                if !(passwordTextField.text?.isEmpty)! {
                    enableContinueButton()
                }
            }
        }
        // Do not add a line break
        return false
    }
    
    @objc func resignKeyboard() {
        if let loginLength = loginTextField.text?.count, loginLength >= minimalLoginLength {
            if !(passwordTextField.text?.isEmpty)! {
                enableContinueButton()
            }
        }
        view.endEditing(true)
    }
    
    @IBAction func goBack(segue: UIStoryboardSegue){
        if let signUpViewController =  segue.source as? SignUpViewController {
            loginTextField.text = signUpViewController.loginField.text
            passwordTextField.text = signUpViewController.passwordField.text
        }
    }
    
    // MARK: - Button Actions
    
    /// continue button has label "Log In" button in storyboard
    @IBAction func continueButton(_ sender: UIButton) {
        if let user = CoreDataManager.shared.validateUser(login: loginTextField.text!, password: passwordTextField.text!){
            messagesDelegate?.userSelected( user )
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                fatalError()
            }
            appDelegate.splitViewMaster?.loginUsingAppLogin = true
            self.performSegue(withIdentifier: "UnwindSegueToUsers", sender: sender)
        } else {
            self.passwordTextField.text = ""
            UIView.animate(withDuration: 0.25, animations: {
                let scaleTransform = CGAffineTransform(scaleX: 1.5, y: 1.1)
                self.passwordTextField.backgroundColor = .red
                self.passwordTextField.transform = scaleTransform
            }) { (_) in
                UIView.animate(withDuration: 0.125) {
                    self.passwordTextField.backgroundColor = .white
                    self.passwordTextField.transform = CGAffineTransform.identity
                }
            }
            
            
//            let alert = UIAlertController(title: "Unable to login.", message: "Wrong login or password", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//            present(alert, animated: true, completion: {
//                self.loginTextField.text = ""
//                self.passwordTextField.text = ""
//            })
        }
    }

    // MARK: Facebook login button actions
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        if FBSDKAccessToken.current() != nil {
            // login successfull
            FBSDKProfile.loadCurrentProfile { (profile, error) in
                let facebookUsername = "\((profile?.firstName)!) \((profile?.lastName)!)"
                if let user = CoreDataManager.shared.getUserWith(login: facebookUsername){
                    // user already registred
                    self.messagesDelegate?.userSelected(user)
                    self.performSegue(withIdentifier: "UnwindSegueToUsers", sender: nil)
                } else {
                    // no already registred user with such login.
                    CoreDataManager.shared.saveNewUser(login: facebookUsername, email:"\(facebookUsername)@gmail.com", password: "qazwsxedc1234554321")
                    if let user = CoreDataManager.shared.getUserWith(login: facebookUsername){
                        self.messagesDelegate?.userSelected(user)
                        self.performSegue(withIdentifier: "UnwindSegueToUsers", sender: nil)
                    }
                }
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        loginTextField.text = ""
        passwordTextField.text = ""
        disableContinueButton()
    }
    
    // MARK: - Private Methods
    
    ///Make Continue button blue and enabled
    private func enableContinueButton() {
        logInButtonOutlet.isEnabled = true
        logInButtonOutlet.backgroundColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
    }
    
    ///Make Continue button gray and disabled
    private func disableContinueButton() {
        logInButtonOutlet.isEnabled = false
        logInButtonOutlet.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    }
}
