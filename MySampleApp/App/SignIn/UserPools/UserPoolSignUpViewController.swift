//
//  UserPoolSignUpViewController.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.10
//
//

import Foundation
import UIKit
import AWSMobileHubHelper
import AWSCognitoIdentityProvider

class UserPoolSignUpViewController: UIViewController {
    let signUpData = SignUpData.signUpData
    
    var pool: AWSCognitoIdentityUserPool?
    var sentTo: String?

    @IBOutlet weak var fullname: UITextField!
    @IBOutlet weak var dob: UITextField!
    @IBOutlet weak var password1: UITextField!
    @IBOutlet weak var password2: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var phone: UITextField!
    
    
    var setName = false
    var setDOB = false
    var setUsername = false
    var setPassword = false
    var setPhone = false
    var setPhoto = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pool = AWSCognitoIdentityUserPool.init(forKey: AWSCognitoUserPoolsSignInProviderKey)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let signUpConfirmationViewController = segue.destination as? UserPoolSignUpConfirmationViewController {
            signUpConfirmationViewController.sentTo = self.sentTo
            signUpConfirmationViewController.user = self.pool?.getUser(self.signUpData.username)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        let ident = identifier
        if ident == "setName" {
            if !self.setName {
                return false
            }
        } else if ident == "setDOB" {
            if !self.setDOB {
                return false
            }
        } else if ident == "setUsername" {
            if !self.setUsername {
                return false
            }
        } else if ident == "setPassword" {
            if !self.setPassword {
                return false
            }
        } else if ident == "setPhoto" {
            if !self.setPhoto {
                return false
            }
        } else if ident == "setPhone" {
            if !self.setPhone {
                return false
            }
        }
        return true
    }
    
    @IBAction func onFullName(_ sender: AnyObject) {
        if let fullNameValue = self.fullname.text, !fullNameValue.isEmpty {
            signUpData.fullname = fullNameValue
            self.setName = true
        } else {
            UIAlertView(title: "Missing Required Fields",
                        message: "Full name is required for registration.",
                        delegate: nil,
                        cancelButtonTitle: "Ok").show()
            return
        }
    }
    
    @IBAction func onDateOfBirth(_ sender: AnyObject) {
        if let dobValue = self.dob.text, !dobValue.isEmpty {
            let monthday = dobValue.index(dobValue.startIndex, offsetBy: 5);
            let ending = dobValue.substring(to: monthday);
            let modified_ending = ending.replacingOccurrences(of: "/", with: "-")
            let startyear = dobValue.index(dobValue.startIndex, offsetBy: 6);
            let year = dobValue.substring(from: startyear)
            signUpData.dob = year + "-" + modified_ending
            self.setDOB = true
        } else {
            UIAlertView(title: "Missing Required Fields",
                        message: "Valid birth date is required for registration.",
                        delegate: nil,
                        cancelButtonTitle: "Ok").show()
            return
        }
    }
    
    func datePickerValueChanged(sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.none
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
        dob.text = dateFormatter.string(from: sender.date)
    }
    
    @IBAction func dp(_ sender: UITextField) {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = UIDatePickerMode.date
        sender.inputView = datePicker
        datePicker.addTarget(self, action: #selector(UserPoolSignUpViewController.datePickerValueChanged(sender:)), for: UIControlEvents.valueChanged)
        
    }
    
    @IBAction func onUserName(_ sender: AnyObject) {
        if let usernameValue = self.username.text, !usernameValue.isEmpty {
            let trimmed_usernameValue = usernameValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let user = self.pool?.getUser(trimmed_usernameValue).confirmedStatus
            if user != AWSCognitoIdentityUserStatus.unknown {
                UIAlertView(title: "Username already exists",
                            message: "Please choose a new username.",
                            delegate: nil,
                            cancelButtonTitle: "Ok").show()
                return
            } else {
                self.signUpData.username = usernameValue
                self.setUsername = true
            }
        } else {
            UIAlertView(title: "Missing Required Fields",
                        message: "Full name is required for registration.",
                        delegate: nil,
                        cancelButtonTitle: "Ok").show()
            return
        }
    }
    
    @IBAction func onPassword(_ sender: AnyObject) {
        guard let pass1Value = self.password1.text, !pass1Value.isEmpty,
            let pass2Value = self.password2.text, !pass2Value.isEmpty else {
                UIAlertView(title: "Missing Required Fields",
                            message: "Please enter your password AND confirm your password.",
                            delegate: nil,
                            cancelButtonTitle: "Ok").show()
                return
        }
        
        if pass1Value != pass2Value {
            UIAlertView(title: "Passwords Do Not Match",
                        message: "Please re-enter and confirm your password.",
                        delegate: nil,
                        cancelButtonTitle: "Ok").show()
            return
        }
        
        if pass1Value.characters.count < 8 {
            UIAlertView(title: "Password too short",
                        message: "Passwords must be at least 8 characters.",
                        delegate: nil,
                        cancelButtonTitle: "Ok").show()
            return
        }
        
        self.signUpData.password = pass1Value
        self.setPassword = true
    }
    
    @IBAction func onPhoto(_ sender: AnyObject) {
        signUpData.photo = "https://s3.amazonaws.com/vescle-userfiles-mobilehub-1713265082/Icon-57%403x.png"
        self.setPhoto = true
    }
    
    @IBAction func onSignUp(_ sender: AnyObject) {

        guard let phoneValue = self.phone.text , !phoneValue.isEmpty else {
            UIAlertView(title: "Missing Required Fields",
                        message: "Please enter your phone number with prepended with country code (i.e. +1).",
                        delegate: nil,
                        cancelButtonTitle: "Ok").show()
            return
        }
        
        var attributes = [AWSCognitoIdentityUserAttributeType]()
        
        if let nameValue = self.signUpData.fullname, !nameValue.isEmpty {
            let name = AWSCognitoIdentityUserAttributeType()
            name?.name = "name"
            name?.value = nameValue
            attributes.append(name!)
        }
        
        if let dobValue = self.signUpData.dob, !dobValue.isEmpty {
            let dob = AWSCognitoIdentityUserAttributeType()
            dob?.name = "birthdate"
            dob?.value = dobValue
            attributes.append(dob!)
        }
        
        if let photoValue = self.signUpData.photo, !photoValue.isEmpty {
            let photo = AWSCognitoIdentityUserAttributeType()
            photo?.name = "picture"
            photo?.value = phoneValue
            attributes.append(photo!)
        }
        
        if let phoneValue = self.phone.text, !phoneValue.isEmpty {
            let phone = AWSCognitoIdentityUserAttributeType()
            phone?.name = "phone_number"
            phone?.value = phoneValue
            attributes.append(phone!)
        }
        
        if let usernameValue = self.signUpData.username, !usernameValue.isEmpty {
            let username = AWSCognitoIdentityUserAttributeType()
            username?.name = "preferred_username"
            username?.value = usernameValue
            attributes.append(username!)
        }
        
        self.setPhone = true
        
        //sign up the user
        self.pool?.signUp(self.signUpData.username, password: self.signUpData.password, userAttributes: attributes, validationData: nil).continueWith {[weak self] (task: AWSTask<AWSCognitoIdentityUserPoolSignUpResponse>) -> AnyObject? in
            guard let strongSelf = self else { return nil }
            DispatchQueue.main.async(execute: { 
                if let error = task.error as? NSError {
                    UIAlertView(title: error.userInfo["__type"] as? String,
                        message: error.userInfo["message"] as? String,
                        delegate: nil,
                        cancelButtonTitle: "Ok").show()
                    return
                }
                
                if let result = task.result as AWSCognitoIdentityUserPoolSignUpResponse! {
                    // handle the case where user has to confirm his identity via email / SMS
                    if (result.user.confirmedStatus != AWSCognitoIdentityUserStatus.confirmed) {
                        strongSelf.sentTo = result.codeDeliveryDetails?.destination
                        strongSelf.performSegue(withIdentifier: "SignUpConfirmSegue", sender:sender)
                    } else {
                        UIAlertView(title: "Registration Complete",
                            message: "Registration was successful.",
                            delegate: nil,
                            cancelButtonTitle: "Ok").show()
                        //strongSelf.presentingViewController?.dismiss(animated: true, completion: nil)
                        _ = strongSelf.navigationController?.popToRootViewController(animated: true)
                    }
                }
                
            })
            return nil
        }
    }

    @IBAction func onCancel(_ sender: AnyObject) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
