//
//  MainViewController.swift
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

import UIKit
import AWSMobileHubHelper

class MainViewController: UITableViewController {
    
    var demoFeatures: [DemoFeature] = []
    var signInObserver: AnyObject!
    var signOutObserver: AnyObject!
    var willEnterForegroundObserver: AnyObject!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
        
        // You need to call `- updateTheme` here in case the sign-in happens before `- viewWillAppear:` is called.
        updateTheme()
        willEnterForegroundObserver = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillEnterForegroundNotification, object: nil, queue: NSOperationQueue.currentQueue()) { _ in
            self.updateTheme()
        }

            presentSignInViewController()
        
        var demoFeature = DemoFeature.init(
            name: NSLocalizedString("User Profile",
                comment: "Label for demo menu option."),
            detail: NSLocalizedString("Retrieve user profile.",
                comment: "Description for demo menu option."),
            icon: "UserIcon", storyboard: "UserIdentity")
        
        demoFeatures.append(demoFeature)
        
        demoFeature = DemoFeature.init(
            name: NSLocalizedString("Lessons",
                comment: "Label for demo menu option."),
            detail: NSLocalizedString("Place to start learning English",
                comment: "Description for demo menu option."),
            icon: "ContentDeliveryIcon", storyboard: "ContentDelivery")
        
        demoFeatures.append(demoFeature)
        
        demoFeature = DemoFeature.init(
            name: NSLocalizedString("Dropbox",
                comment: "Label for demo menu option."),
            detail: NSLocalizedString("Save user files in the cloud and sync user data in key/value pairs.",
            comment: "Description for demo menu option."),
            icon: "UserFilesIcon", storyboard: "UserFiles")
        
        demoFeatures.append(demoFeature)
        
        demoFeature = DemoFeature.init(
            name: NSLocalizedString("App Analytics",
                comment: "Label for demo menu option."),
            detail: NSLocalizedString("Collect, visualize and export app usage metrics.",
            comment: "Description for demo menu option."),
            icon: "AppAnalyticsIcon", storyboard: "AppAnalytics")
        
        demoFeatures.append(demoFeature)
        
        demoFeature = DemoFeature.init(
            name: NSLocalizedString("Dynamodb",
                comment: "Label for demo menu option."),
            detail: NSLocalizedString("Store data in the cloud.",
                comment: "Description for demo menu option."),
            icon: "NoSQLIcon", storyboard: "NoSQLDatabase")
        
        demoFeatures.append(demoFeature)
        
        demoFeature = DemoFeature.init(
            name: NSLocalizedString("Welcome",
                comment: "Label for demo menu option."),
            detail: NSLocalizedString("Go to the welcome page",
                comment: "Description for demo menu option."),
            icon: "UserIcon", storyboard: "Welcome")
        
        
        demoFeatures.append(demoFeature)

                signInObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignInNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self] (note: NSNotification) -> Void in
                        guard let strongSelf = self else { return }
                        print("Sign In Observer observed sign in.")
                        strongSelf.setupRightBarButtonItem()
                        // You need to call `updateTheme` here in case the sign-in happens after `- viewWillAppear:` is called.
                        strongSelf.updateTheme()
                })
                
                signOutObserver = NSNotificationCenter.defaultCenter().addObserverForName(AWSIdentityManagerDidSignOutNotification, object: AWSIdentityManager.defaultIdentityManager(), queue: NSOperationQueue.mainQueue(), usingBlock: {[weak self](note: NSNotification) -> Void in
                        guard let strongSelf = self else { return }
                        print("Sign Out Observer observed sign out.")
                        strongSelf.setupRightBarButtonItem()
                        strongSelf.updateTheme()
                })
                
                setupRightBarButtonItem()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(signInObserver)
        NSNotificationCenter.defaultCenter().removeObserver(signOutObserver)
        NSNotificationCenter.defaultCenter().removeObserver(willEnterForegroundObserver)
    }

    func setupRightBarButtonItem() {
            struct Static {
                static var onceToken: dispatch_once_t = 0
            }
            
            dispatch_once(&Static.onceToken, {
                let loginButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .Done, target: self, action: nil)
                self.navigationItem.rightBarButtonItem = loginButton
            })
            
            if (AWSIdentityManager.defaultIdentityManager().loggedIn) {
                navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-Out", comment: "Label for the logout button.")
                navigationItem.rightBarButtonItem!.action = "handleLogout"
            }
    }
    
    func presentSignInViewController() {
        if !AWSIdentityManager.defaultIdentityManager().loggedIn {
            let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
            let signInViewController = storyboard.instantiateViewControllerWithIdentifier("SignIn") as! SignInViewController
            presentViewController(signInViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - UITableViewController delegates
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MainViewCell")!
        let demoFeature = demoFeatures[indexPath.row]
        cell.imageView!.image = UIImage(named: demoFeature.icon)
        cell.textLabel!.text = demoFeature.displayName
        cell.detailTextLabel!.text = demoFeature.detailText
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return demoFeatures.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let demoFeature = demoFeatures[indexPath.row]
        let storyboard = UIStoryboard(name: demoFeature.storyboard, bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier(demoFeature.storyboard)
        self.navigationController!.pushViewController(viewController, animated: true)
    }

    func updateTheme() {
        let settings = ColorThemeSettings.sharedInstance
        settings.loadSettings { (themeSettings: ColorThemeSettings?, error: NSError?) -> Void in
            guard let themeSettings = themeSettings else {
                 print("Failed to load color: \(error)")
                return
            }
            dispatch_async(dispatch_get_main_queue(), {
                let titleTextColor: UIColor = themeSettings.theme.titleTextColor.UIColorFromARGB()
                self.navigationController!.navigationBar.barTintColor = themeSettings.theme.titleBarColor.UIColorFromARGB()
                self.view.backgroundColor = themeSettings.theme.backgroundColor.UIColorFromARGB()
                self.navigationController!.navigationBar.tintColor = titleTextColor
                self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: titleTextColor]
            })
        }
    }
    
    
    func handleLogout() {
        if (AWSIdentityManager.defaultIdentityManager().loggedIn) {
            ColorThemeSettings.sharedInstance.wipe()
            AWSIdentityManager.defaultIdentityManager().logoutWithCompletionHandler({(result: AnyObject?, error: NSError?) -> Void in
                self.navigationController!.popToRootViewControllerAnimated(false)
                self.setupRightBarButtonItem()
                    self.presentSignInViewController()
            })
            // print("Logout Successful: \(signInProvider.getDisplayName)");
        } else {
            assert(false)
        }
    }
}

class FeatureDescriptionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "Back", style: .Plain, target: nil, action: nil)
    }
}