//
//  SignInViewController.swift
//  MySampleApp
//
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.4
//
//

import UIKit
import AWSMobileHubHelper
import AWSCognitoIdentityProvider

class SignInViewController: UIViewController {
    @IBOutlet weak var anchorView: UIView!

    @IBOutlet weak var customProviderButton: UIButton!
    @IBOutlet weak var customCreateAccountButton: UIButton!
    @IBOutlet weak var customForgotPasswordButton: UIButton!
    //Editing Point
    //@IBOutlet weak var customUserIdField: UITextField!
    @IBOutlet weak var customEmailAddressField: UITextField!
    @IBOutlet weak var customPasswordField: UITextField!
    @IBOutlet weak var leftHorizontalBar: UIView!
    @IBOutlet weak var rightHorizontalBar: UIView!
    @IBOutlet weak var orSignInWithLabel: UIView!
    
    
    var didSignInObserver: AnyObject!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
         print("Sign In Loading.")
        
            didSignInObserver =  NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignInNotification,
                object: AWSIdentityManager.defaultIdentityManager(),
                queue: NSOperationQueue.mainQueue(),
                usingBlock: {(note: NSNotification) -> Void in
                    // perform successful login actions here
            })
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(didSignInObserver)
    }
    
    func dimissController() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Utility Methods

    
    func handleLoginWithSignInProvider(signInProvider: AWSSignInProvider) {
        
        AWSIdentityManager.defaultIdentityManager().loginWithSignInProvider(signInProvider, completionHandler: {(result: AnyObject?, error: NSError?) -> Void in
            // If no error reported by SignInProvider, discard the sign-in view controller.
            if error == nil {
                dispatch_async(dispatch_get_main_queue(),{
                        self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
            else {
                dispatch_async(dispatch_get_main_queue(),{
                    if(error?.code == 16){
                        self.displayError("", info: "Incorrect username or password")
                    }
                    else{
                        self.displayError("Error", info:error.debugDescription)
                    }
                    
                })
            }
        })
    }

    func showErrorDialog(loginProviderName: String, withError error: NSError) {
         print("\(loginProviderName) failed to sign in w/ error: \(error)")
        let alertController = UIAlertController(title: NSLocalizedString("Sign-in Provider Sign-In Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("\(loginProviderName) failed to sign in w/ error: \(error)", comment: "Sign-in message structure for sign-in failure."), preferredStyle: .Alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label to cancel sign-in failure."), style: .Cancel, handler: nil)
        alertController.addAction(doneAction)
        presentViewController(alertController, animated: true, completion: nil)
    }

    // MARK: - IBActions
    
    
    //var passwordAuthenticationCompletion: AWSTaskCompletionSource = AWSTaskCompletionSource.init()
    @IBAction func handleCustomLogin(sender: UIButton) {
        
        if (customEmailAddressField.text != "") && (customPasswordField.text != "") {
            
            let customSignInProvider = AWSCUPIdPSignInProvider.sharedInstance
            
            // Push email address and password to AWSCUPIdPSignInProvider

            customSignInProvider.customUserEmailAddress = customEmailAddressField.text
            customSignInProvider.customPasswordField = customPasswordField.text
            
            handleLoginWithSignInProvider(customSignInProvider)
        }
    }
 
    /*
    
    func handleCustomLogin() {
        
        if (customUserIdField.text == nil) {
            self.displayError("User Name Empty")
        }
        else if (customPasswordField.text == nil){
            self.displayError("Password Empty")

        }
        else {
            let user = (UIApplication.sharedApplication().delegate as! AppDelegate).userPool!.getUser(customUserIdField.text!)

            user.getSession(customUserIdField.text!, password: customPasswordField.text!, validationData: nil, scopes: nil).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: {
                (task:AWSTask!) -> AnyObject! in
                
                if task.error == nil {
                    
                    
                    dispatch_async(dispatch_get_main_queue(),{
                        self.dismissViewControllerAnimated(true, completion: nil)
                    })
                } else {
                    self.displayError(task.error.debugDescription)
                }
                
                return nil
            })
            
        }
 
        //self.passwordAuthenticationCompletion.setResult(AWSCognitoIdentityPasswordAuthenticationDetails(username: customUserIdField.text!, password: customPasswordField.text!))
    }
    
    */
    
    func displayError(title: String, info:String) {
        // Handle Create Account action for custom sign-in here.
        let alertController = UIAlertController(title: NSLocalizedString(title, comment: "Label for custom sign-in dialog."), message: NSLocalizedString(info, comment: "Sign-in message structure for custom sign-in stub."), preferredStyle: .Alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Done", comment: "Label to complete stubbed custom sign-in."), style: .Cancel, handler: nil)
        alertController.addAction(doneAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func handleCustomForgotPassword() {
        // Handle Forgot Password action for custom sign-in here.
        let alertController = UIAlertController(title: NSLocalizedString("Custom Sign-In Demo", comment: "Label for custom sign-in dialog."), message: NSLocalizedString("This is just a demo of custom sign-in Forgot Password button.", comment: "Sign-in message structure for custom sign-in stub."), preferredStyle: .Alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Done", comment: "Label to complete stubbed custom sign-in."), style: .Cancel, handler: nil)
        alertController.addAction(doneAction)
        presentViewController(alertController, animated: true, completion: nil)
    }

    func anchorViewForFacebook() -> UIView {
            return orSignInWithLabel
    }
}
