//
//  UserFilesViewController.swift
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
import WebKit
import MediaPlayer
import MobileCoreServices
import AWSMobileHubHelper

import ObjectiveC

let UserFilesPublicDirectoryName = "public"
let UserFilesPrivateDirectoryName = "private"
private var cellAssociationKey: UInt8 = 0

class UserFilesViewController: UITableViewController {
    
    @IBOutlet weak var pathLabel: UILabel!
    
    var prefix: String!
    
    private var manager: AWSUserFileManager!
    private var contents: [AWSContent]?
    private var dateFormatter: NSDateFormatter!
    private var marker: String?
    private var didLoadAllContents: Bool!
    
    // MARK:- View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        manager = AWSUserFileManager.defaultUserFileManager()
        
        // Sets up the UIs.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "showContentManagerActionOptions:")
        
        // Sets up the date formatter.
        dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.locale = NSLocale.currentLocale()
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        didLoadAllContents = false
        
        if let prefix = prefix {
            print("Prefix already initialized to \(prefix)")
        } else {
            self.prefix = "\(UserFilesPublicDirectoryName)/"
        }
        refreshContents()
        updateUserInterface()
        loadMoreContents()
        
    }
    
    private func mergeVideo(localContent: AWSLocalContent){
        localContent.uploadWithPinOnCompletion(false, progressBlock: {[weak self](content: AWSLocalContent?, progress: NSProgress?) -> Void in
            guard let strongSelf = self else { return }
            dispatch_async(dispatch_get_main_queue()) {
                // Update the upload UI if it is a new upload and the table is not yet updated
                if(strongSelf.tableView.numberOfRowsInSection(0) == 0 || strongSelf.tableView.numberOfRowsInSection(0) < strongSelf.manager.uploadingContents.count) {
                    strongSelf.updateUploadUI()
                } else {
                    for uploadContent in strongSelf.manager.uploadingContents {
                        if uploadContent.key == content?.key {
                            let index = strongSelf.manager.uploadingContents.indexOf(uploadContent)!
                            let indexPath = NSIndexPath(forRow: index, inSection: 0)
                            strongSelf.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                        }
                    }
                }
            }
            }, completionHandler: {[weak self](content: AWSContent?, error: NSError?) -> Void in
                guard let strongSelf = self else { return }
                strongSelf.updateUploadUI()
                if let error = error {
                    print("Failed to upload an object. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to upload an object.", cancelButtonTitle: "OK")
                } else {
                    strongSelf.refreshContents()
                }
            })
        updateUploadUI()
    }
    
    private func updateUserInterface() {
        dispatch_async(dispatch_get_main_queue()) {
            if let prefix = self.prefix {
                if (prefix.hasPrefix(UserFilesPublicDirectoryName)) {
                    self.pathLabel.text = "\(prefix.substringFromIndex(UserFilesPublicDirectoryName.endIndex))"
                }
                if (prefix.hasPrefix(UserFilesPrivateDirectoryName)) {
                    let userId = AWSIdentityManager.defaultIdentityManager().userName!
                    /*let subStringRange: Range<String.Index> = prefix.startIndex.advancedBy(UserFilesPrivateDirectoryName.characters.count + userId.characters.count + 1)..<prefix.endIndex.advancedBy(-1)*/
                    self.pathLabel.text = "\(userId))"
                }
            } else {
                self.pathLabel.text = "/"
            }
            self.tableView.reloadData()
        }
    }
    
    // MARK:- Content Manager user action methods
    
    @IBAction func changeDirectory(sender: UISegmentedControl) {
        switch(sender.selectedSegmentIndex) {
        case 0: //Public Directory
            manager = AWSUserFileManager.defaultUserFileManager()
            prefix = "\(UserFilesPublicDirectoryName)/"
            break
        case 1: //Private Directory
            if (AWSIdentityManager.defaultIdentityManager().loggedIn) {
                manager = AWSUserFileManager.defaultUserFileManager()
                let userId = AWSIdentityManager.defaultIdentityManager().userName!
                prefix = "\(UserFilesPrivateDirectoryName)/\(userId)/"
            } else {
                sender.selectedSegmentIndex = 0
                    let alertController = UIAlertController(title: "Info", message: "Private user file storage is only available to users who are signed-in. Would you like to sign in?", preferredStyle: .Alert)
                    let signInAction = UIAlertAction(title: "Sign In", style: .Default, handler: {[weak self](action: UIAlertAction) -> Void in
                        guard let strongSelf = self else { return }
                        let loginStoryboard: UIStoryboard = UIStoryboard(name: "SignIn", bundle: nil)
                        let loginController: UIViewController = loginStoryboard.instantiateViewControllerWithIdentifier("SignIn")
                        strongSelf.navigationController?.pushViewController(loginController, animated: true)
                        })
                    alertController.addAction(signInAction)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    presentViewController(alertController, animated: true, completion: nil)
            }
            break
        default:
            break;
        }
        contents = []
        loadMoreContents()
    }
    
    func showContentManagerActionOptions(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let uploadObjectAction = UIAlertAction(title: "Upload", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.showImagePicker()
            })
        alertController.addAction(uploadObjectAction)
        
        let createFolderAction = UIAlertAction(title: "New Folder", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.askForDirectoryName()
            })
        alertController.addAction(createFolderAction)
        let refreshAction = UIAlertAction(title: "Refresh", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.refreshContents()
            })
        alertController.addAction(refreshAction)
        let downloadObjectsAction = UIAlertAction(title: "Download Recent", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.downloadObjectsToFillCache()
            })
        alertController.addAction(downloadObjectsAction)
        let changeLimitAction = UIAlertAction(title: "Set Cache Size", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.showDiskLimitOptions()
            })
        alertController.addAction(changeLimitAction)
        let removeAllObjectsAction = UIAlertAction(title: "Clear Cache", style: .Destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.manager.clearCache()
            self.updateUserInterface()
            })
        alertController.addAction(removeAllObjectsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func refreshContents() {
        marker = nil
        loadMoreContents()
    }
    
    private func loadMoreContents() {
        manager.listAvailableContentsWithPrefix(prefix, marker: marker, completionHandler: {[weak self](contents: [AWSContent]?, nextMarker: String?, error: NSError?) -> Void in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to load the list of contents.", cancelButtonTitle: "OK")
                print("Failed to load the list of contents. \(error)")
            }
            if let contents = contents where contents.count > 0 {
                strongSelf.contents = contents
                if let nextMarker = nextMarker where !nextMarker.isEmpty {
                    strongSelf.didLoadAllContents = false
                } else {
                    strongSelf.didLoadAllContents = true
                }
                strongSelf.marker = nextMarker
            }
            strongSelf.updateUserInterface()
            })
    }
    
    private func showDiskLimitOptions() {
        let alertController = UIAlertController(title: "Disk Cache Size", message: nil, preferredStyle: .ActionSheet)
        for number: Int in [1, 5, 20, 50, 100] {
            let byteLimitOptionAction = UIAlertAction(title: "\(number) MB", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.manager.maxCacheSize = UInt(number) * 1024 * 1024
                self.updateUserInterface()
                })
            alertController.addAction(byteLimitOptionAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func downloadObjectsToFillCache() {
        manager.listRecentContentsWithPrefix(prefix, completionHandler: {[weak self](result: AnyObject?, error: NSError?) -> Void in
            guard let strongSelf = self else { return }
            if let resultArray: [AWSContent] = result as? [AWSContent] {
                for content: AWSContent in resultArray {
                    if !content.cached && !content.directory {
                        strongSelf.downloadContent(content, pinOnCompletion: false)
                    }
                }
            }
            })
    }
    
    // MARK:- Content user action methods
    
    private func showActionOptionsForContent(rect: CGRect, content: AWSContent) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        if alertController.popoverPresentationController != nil {
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = CGRectMake(rect.midX, rect.midY, 1.0, 1.0)
        }
        if content.cached {
            let openAction = UIAlertAction(title: "Open", style: .Default, handler: {(action: UIAlertAction) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    self.openContent(content)
                }
            })
            alertController.addAction(openAction)
        }
        
        // Allow opening of remote files natively or in browser based on their type.
        let openRemoteAction = UIAlertAction(title: "Open Remote", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.openRemoteContent(content)
            
            })
        alertController.addAction(openRemoteAction)
        
        // If the content hasn't been downloaded, and it's larger than the limit of the cache,
        // we don't allow downloading the contentn.
        if content.knownRemoteByteCount + 4 * 1024 < self.manager.maxCacheSize {
            // 4 KB is for local metadata.
            var title = "Download"
            
            if content.knownRemoteLastModifiedDate.compare(content.downloadedDate) == .OrderedDescending {
                title = "Download Latest Version"
            }
            let downloadAction = UIAlertAction(title: title, style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
                self.downloadContent(content, pinOnCompletion: false)
                })
            alertController.addAction(downloadAction)
        }
        let downloadAndPinAction = UIAlertAction(title: "Download & Pin", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.downloadContent(content, pinOnCompletion: true)
            })
        alertController.addAction(downloadAndPinAction)
        if content.cached {
            if content.pinned {
                let unpinAction = UIAlertAction(title: "Unpin", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
                    content.unPin()
                    self.updateUserInterface()
                    })
                alertController.addAction(unpinAction)
            } else {
                let pinAction = UIAlertAction(title: "Pin", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
                    content.pin()
                    self.updateUserInterface()
                    })
                alertController.addAction(pinAction)
            }
            let removeAction = UIAlertAction(title: "Delete Local Copy", style: .Destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
                content.removeLocal()
                self.updateUserInterface()
                })
            alertController.addAction(removeAction)
        }
        
        let removeFromRemoteAction = UIAlertAction(title: "Delete Remote File", style: .Destructive, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.confirmForRemovingContent(content)
            })
        
        alertController.addAction(removeFromRemoteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func downloadContent(content: AWSContent, pinOnCompletion: Bool) {
        content.downloadWithDownloadType(.IfNewerExists, pinOnCompletion: pinOnCompletion, progressBlock: {[weak self](content: AWSContent?, progress: NSProgress?) -> Void in
            guard let strongSelf = self else { return }
            if strongSelf.contents!.contains( {$0 == content} ) {
                let row = strongSelf.contents!.indexOf({$0  == content!})!
                let indexPath = NSIndexPath(forRow: row, inSection: 1)
                strongSelf.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
            }
            }, completionHandler: {[weak self](content: AWSContent?, data: NSData?, error: NSError?) -> Void in
                guard let strongSelf = self else { return }
                if let error = error {
                    print("Failed to download a content from a server. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to download a content from a server.", cancelButtonTitle: "OK")
                }
                strongSelf.updateUserInterface()
            })
    }
    
    private func openContent(content: AWSContent) {
        if content.isAudioVideo() { // Video and sound files
            let directories: [AnyObject] = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
            let cacheDirectoryPath = directories.first as! String
            
            let movieURL: NSURL = NSURL(fileURLWithPath: "\(cacheDirectoryPath)/\(content.key.getLastPathComponent())")
            
            content.cachedData.writeToURL(movieURL, atomically: true)
            
            let controller: MPMoviePlayerViewController = MPMoviePlayerViewController(contentURL: movieURL)
            controller.moviePlayer.prepareToPlay()
            controller.moviePlayer.play()
            presentMoviePlayerViewControllerAnimated(controller)
        } else if content.isImage() { // Image files
            // Image files
            let storyboard = UIStoryboard(name: "UserFiles", bundle: nil)
            let imageViewController = storyboard.instantiateViewControllerWithIdentifier("UserFilesImageViewController") as! UserFilesImageViewController
            imageViewController.image = UIImage(data: content.cachedData)
            imageViewController.title = content.key
            navigationController?.pushViewController(imageViewController, animated: true)
        } else {
            showSimpleAlertWithTitle("Sorry!", message: "We can only open image, video, and sound files.", cancelButtonTitle: "OK")
        }
    }
    
    private func openRemoteContent(content: AWSContent) {
        content.getRemoteFileURLWithCompletionHandler({[weak self](url: NSURL?, error: NSError?) -> Void in
            guard let strongSelf = self else { return }
            guard let url = url else {
                print("Error getting URL for file. \(error)")
                return
            }
            if content.isAudioVideo() { // Open Audio and Video files natively in app.
                let controller: MPMoviePlayerViewController = MPMoviePlayerViewController(contentURL: url)
                controller.moviePlayer.prepareToPlay()
                controller.moviePlayer.play()
                strongSelf.presentMoviePlayerViewControllerAnimated(controller)
            } else { // Open other file types like PDF in web browser.
                //UIApplication.sharedApplication().openURL(url)
                let storyboard: UIStoryboard = UIStoryboard(name: "UserFiles", bundle: nil)
                let webViewController: UserFilesWebViewController = storyboard.instantiateViewControllerWithIdentifier("UserFilesWebViewController") as! UserFilesWebViewController
                webViewController.url = url
                webViewController.title = content.key
                strongSelf.navigationController?.pushViewController(webViewController, animated: true)
            }
            })
    }
    
    private func confirmForRemovingContent(content: AWSContent) {
        let alertController = UIAlertController(title: "Confirm", message: "Do you want to delete the content from the server? This cannot be undone.", preferredStyle: .Alert)
        let okayAction = UIAlertAction(title: "Yes", style: .Default, handler: {[weak self](action: UIAlertAction) -> Void in
            guard let strongSelf = self else { return }
            strongSelf.removeContent(content)
            })
        alertController.addAction(okayAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func removeContent(content: AWSContent) {
        content.removeRemoteContentWithCompletionHandler({[weak self](content: AWSContent?, error: NSError?) -> Void in
            guard let strongSelf = self else { return }
            if let error = error {
                print("Failed to delete an object from the remote server. \(error)")
                dispatch_async(dispatch_get_main_queue()) {
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to delete an object from the remote server.", cancelButtonTitle: "OK")
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    strongSelf.showSimpleAlertWithTitle("Object Deleted", message: "The object has been deleted successfully.", cancelButtonTitle: "OK")
                }
                strongSelf.refreshContents()
            }
            })
    }
    
    // MARK:- Content uploads
    
    private func showImagePicker() {
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeImage as String, kUTTypeMovie as String]
        imagePickerController.delegate = self
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    private func askForFilename(data: NSData) {
        let alertController = UIAlertController(title: "File Name", message: "Please specify the file name.", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler(nil)
        let doneAction = UIAlertAction(title: "Done", style: .Default, handler: {[unowned self](action: UIAlertAction) -> Void in
            let specifiedKey = alertController.textFields!.first!.text!
            if specifiedKey.characters.count == 0 {
                self.showSimpleAlertWithTitle("Error", message: "The file name cannot be empty.", cancelButtonTitle: "OK")
                return
            } else {
                let key: String = "\(self.prefix)\(specifiedKey)"
                self.uploadWithData(data, forKey: key)
            }
            })
        alertController.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func askForDirectoryName() {
        let alertController: UIAlertController = UIAlertController(title: "Directory Name", message: "Please specify the directory name.", preferredStyle: .Alert)
        alertController.addTextFieldWithConfigurationHandler(nil)
        let doneAction: UIAlertAction = UIAlertAction(title: "Done", style: .Default, handler: {[weak self](action: UIAlertAction) -> Void in
            guard let strongSelf = self else { return }
            let specifiedKey = alertController.textFields!.first!.text!
            if specifiedKey.characters.count == 0 {
                strongSelf.showSimpleAlertWithTitle("Error", message: "The directory name cannot be empty.", cancelButtonTitle: "OK")
                return
            } else {
                let key = "\(strongSelf.prefix)\(specifiedKey)/"
                strongSelf.createFolderForKey(key)
            }
            })
        alertController.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func uploadLocalContent(localContent: AWSLocalContent) {
        localContent.uploadWithPinOnCompletion(false, progressBlock: {[weak self](content: AWSLocalContent?, progress: NSProgress?) -> Void in
            guard let strongSelf = self else { return }
            dispatch_async(dispatch_get_main_queue()) {
                // Update the upload UI if it is a new upload and the table is not yet updated
                if(strongSelf.tableView.numberOfRowsInSection(0) == 0 || strongSelf.tableView.numberOfRowsInSection(0) < strongSelf.manager.uploadingContents.count) {
                    strongSelf.updateUploadUI()
                } else {
                    for uploadContent in strongSelf.manager.uploadingContents {
                        if uploadContent.key == content?.key {
                            let index = strongSelf.manager.uploadingContents.indexOf(uploadContent)!
                            let indexPath = NSIndexPath(forRow: index, inSection: 0)
                            strongSelf.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                        }
                    }
                }
            }
            }, completionHandler: {[weak self](content: AWSContent?, error: NSError?) -> Void in
                guard let strongSelf = self else { return }
                strongSelf.updateUploadUI()
                if let error = error {
                    print("Failed to upload an object. \(error)")
                    strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to upload an object.", cancelButtonTitle: "OK")
                } else {
                    strongSelf.refreshContents()
                }
            })
        updateUploadUI()
    }
    
    private func uploadWithData(data: NSData, forKey key: String) {
        let localContent = manager.localContentWithData(data, key: key)
        uploadLocalContent(localContent)
    }
    
    private func createFolderForKey(key: String) {
        let localContent = manager.localContentWithData(nil, key: key)
        uploadLocalContent(localContent)
    }
    
    private func updateUploadUI() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return manager.uploadingContents.count
        }
        if let contents = self.contents {
            return contents.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("UserFilesUploadCell", forIndexPath: indexPath) as! UserFilesUploadCell
            let localContent: AWSLocalContent = manager.uploadingContents[indexPath.row]
            cell.prefix = prefix
            cell.localContent = localContent
            return cell
        }
        
        let cell: UserFilesCell = tableView.dequeueReusableCellWithIdentifier("UserFilesCell", forIndexPath: indexPath) as! UserFilesCell
        
        let content: AWSContent = contents![indexPath.row]
        cell.prefix = prefix
        cell.content = content
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let contents = self.contents where indexPath.row == contents.count - 1  {
            if (!didLoadAllContents) {
                loadMoreContents()
            }
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        // Process only if it is a listed file. Ignore actions for files that are uploading.
        if(indexPath.section != 0) {
            let content = contents![indexPath.row]
            if content.directory {
                let storyboard: UIStoryboard = UIStoryboard(name: "UserFiles", bundle: nil)
                let viewController: UserFilesViewController = storyboard.instantiateViewControllerWithIdentifier("UserFiles") as! UserFilesViewController
                viewController.prefix = content.key
                navigationController?.pushViewController(viewController, animated: true)
            } else {
                let rowRect = tableView.rectForRowAtIndexPath(indexPath);
                showActionOptionsForContent(rowRect, content: content)
            }
        }
    }
}

// MARK:- UIImagePickerControllerDelegate

extension UserFilesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        // Handle image uploads
        if mediaType.isEqualToString(kUTTypeImage as String) {
            let image: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            askForFilename(UIImagePNGRepresentation(image)!)
        }
        // Handle Video Uploads
        if mediaType.isEqualToString(kUTTypeMovie as String) {
            let videoURL: NSURL = info[UIImagePickerControllerMediaURL] as! NSURL
            askForFilename(NSData(contentsOfURL: videoURL)!)
        }
    }
}

class UserFilesCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var keepImageView: UIImageView!
    @IBOutlet weak var downloadedImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var prefix: String?
    
    var content: AWSContent! {
        didSet {
            var displayFilename: String = self.content.key
            if let prefix = self.prefix {
                if displayFilename.characters.count > prefix.characters.count {
                    displayFilename = displayFilename.substringFromIndex(prefix.endIndex)
                }
            }
            fileNameLabel.text = displayFilename
            downloadedImageView.hidden = !content.cached
            keepImageView.hidden = !content.pinned
            var contentByteCount: UInt = content.fileSize
            if contentByteCount == 0 {
                contentByteCount = content.knownRemoteByteCount
            }
            
            if content.directory {
                detailLabel.text = "This is a folder"
                accessoryType = .DisclosureIndicator
            } else {
                detailLabel.text = contentByteCount.aws_stringFromByteCount()
                accessoryType = .None
            }
            
            if content.knownRemoteLastModifiedDate.compare(content.downloadedDate) == .OrderedDescending {
                detailLabel.text = "\(detailLabel.text!) - New Version Available"
                detailLabel.textColor = UIColor.blueColor()
            } else {
                detailLabel.textColor = UIColor.blackColor()
            }
            
            if content.status == .Running {
                progressView.progress = Float(content.progress.fractionCompleted)
                progressView.hidden = false
            } else {
                progressView.hidden = true
            }
        }
    }
}

class UserFilesImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        imageView.image = image
    }
}

class UserFilesWebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    var url: NSURL!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        webView.delegate = self
        webView.dataDetectorTypes = .None
        webView.scalesPageToFit = true
        webView.loadRequest(NSURLRequest(URL: url))
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        print("The URL content failed to load \(error)")
        webView.loadHTMLString("<html><body><h1>Cannot Open the content of the URL.</h1></body></html>", baseURL: nil)
    }
}

class UserFilesUploadCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var prefix: String?
    
    var localContent: AWSLocalContent! {
        didSet {
            var displayFilename: String = localContent.key
            displayFilename = displayFilename.stringByReplacingOccurrencesOfString(AWSIdentityManager.defaultIdentityManager().userName!, withString: "<private>")
            fileNameLabel.text = displayFilename
            progressView.progress = Float(localContent.progress.fractionCompleted)
        }
    }
}

// MARK: - Utility

extension UserFilesViewController {
    private func showSimpleAlertWithTitle(title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
}

extension AWSContent {
    private func isAudioVideo() -> Bool {
        let lowerCaseKey = self.key.lowercaseString
        return lowerCaseKey.hasSuffix(".mov")
            || lowerCaseKey.hasSuffix(".mp4")
            || lowerCaseKey.hasSuffix(".mpv")
            || lowerCaseKey.hasSuffix(".3gp")
            || lowerCaseKey.hasSuffix(".mpeg")
            || lowerCaseKey.hasSuffix(".aac")
            || lowerCaseKey.hasSuffix(".mp3")
    }
    
    private func isImage() -> Bool {
        let lowerCaseKey = self.key.lowercaseString
        return lowerCaseKey.hasSuffix(".jpg")
            || lowerCaseKey.hasSuffix(".png")
            || lowerCaseKey.hasSuffix(".jpeg")
    }
}

extension UInt {
    private func aws_stringFromByteCount() -> String {
        if self < 1024 {
            return "\(self) B"
        }
        if self < 1024 * 1024 {
            return "\(self / 1024) KB"
        }
        if self < 1024 * 1024 * 1024 {
            return "\(self / 1024 / 1024) MB"
        }
        return "\(self / 1024 / 1024 / 1024) GB"
    }
}

extension String {
    private func getLastPathComponent() -> String {
        let nsstringValue: NSString = self
        return nsstringValue.lastPathComponent
    }
}
