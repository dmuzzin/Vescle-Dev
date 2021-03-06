//
//  PostVescleView.swift
//  MySampleApp
//
//  Created by Jonathan Sussman on 2/21/17.
//
//

import Foundation
import UIKit
import AVFoundation
import AWSS3
import AssetsLibrary
import Photos
import AWSDynamoDB
import AWSMobileHubHelper

extension PHAsset {
    
    var originalFilename: String? {
        
        var fname:String?
        
        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if let resource = resources.first {
                fname = resource.originalFilename
            }
        }
        
        if fname == nil {
            // this is an undocumented workaround that works as of iOS 9.1
            fname = self.value(forKey: "filename") as? String
        }
        
        return fname
    }
}

func getCurrentMillis()->Int64{
    return  Int64(NSDate().timeIntervalSince1970 * 1000)
}

class PostVescleViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource,UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var caption: UITextField!
    @IBOutlet weak var timeChosen: UILabel!
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var ImagePicked: UIImageView!
    @IBOutlet weak var postButton: UIButton?
    var myActivityIndicator: UIActivityIndicatorView!

    
    let imagePicker = UIImagePickerController()
    var imageURL: NSURL!
    var createFileName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpActivityIndicator()
        postButton?.layer.cornerRadius = 10
        postButton?.layer.borderColor = UIColor.white.cgColor
        postButton?.layer.borderWidth = 1
        timePicker.delegate = self
        timePicker.dataSource = self
        self.caption.delegate = self
        self.hideKeyboard()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) { // became first responder
        
        //move textfields up
        let myScreenRect: CGRect = UIScreen.main.bounds
        let keyboardHeight : CGFloat = 216
        
        UIView.beginAnimations( "animateView", context: nil)
        var needToMove: CGFloat = 0
        
        var frame : CGRect = self.view.frame
        if (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height + */UIApplication.shared.statusBarFrame.size.height > (myScreenRect.size.height - keyboardHeight)) {
            needToMove = (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height +*/ UIApplication.shared.statusBarFrame.size.height) - (myScreenRect.size.height - keyboardHeight);
        }
        
        frame.origin.y = -needToMove
        self.view.frame = frame
        UIView.commitAnimations()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //move textfields back down
        UIView.beginAnimations( "animateView", context: nil)
        var frame : CGRect = self.view.frame
        frame.origin.y = 0
        self.view.frame = frame
        UIView.commitAnimations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isBeingPresented || self.isMovingToParentViewController {
            if UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.front) {
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.camera
                present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    
    let pickerData = [
        ["1","2","3","4","5","6","7","8","9","10",
         "11","12","13", "14", "15", "16","17","18","19","20",
         "21","22","23", "24", "25", "26","27","28","29","30"],
        ["Seconds","Minutes","Hours","Days"]
    ]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView,numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView,titleForRow row: Int,forComponent component: Int) -> String? {
        return pickerData[component][row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.white
        pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 18)
        pickerLabel.textAlignment = NSTextAlignment.center
        pickerLabel.text = pickerData[component][row]
        return pickerLabel
    }
    
    //MARK - Instance Methods
    func updateLabel(){
        let time = pickerData[0][timePicker.selectedRow(inComponent: 0)]
        let type = pickerData[1][timePicker.selectedRow(inComponent: 1)]
        timeChosen.text = "Burst Time: " + time + " " + type
    }
    
    func pickerView(_ pickerView: UIPickerView,didSelectRow row: Int,inComponent component: Int)
    {
        updateLabel()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true;
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        ImagePicked.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        ImagePicked.backgroundColor = UIColor.clear
        ImagePicked.contentMode = UIViewContentMode.scaleAspectFill
        
        var imageToSave: UIImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        createFileName = ProcessInfo.processInfo.globallyUniqueString + ".jpeg"
        
        let writePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(createFileName)
        
        //getting actual image
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let data = UIImageJPEGRepresentation(ImagePicked.image!, 0.6)
        do {
            _ = try data?.write(to: writePath)
        } catch let error {
            print(error)
        }
        
        imageURL = writePath as NSURL!
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func generateImageUrl(fileName: String) -> NSURL
    {
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
        let data = UIImageJPEGRepresentation(ImagePicked.image!, 0.6)
        do {
            _ = try data?.write(to: fileURL as URL, options: .atomic)
        } catch let error {
            print(error)
        }
        return fileURL
    }
    
    func remoteImageWithUrl(fileName: String)
    {
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
        do {
            try FileManager.default.removeItem(at: fileURL as URL)
        } catch
        {
            print(error)
        }
    }
    

    
    func setUpActivityIndicator()
    {
        //Create Activity Indicator
        myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        
        // Position Activity Indicator in the center of the main view
        myActivityIndicator.center = view.center
        
        // If needed, you can prevent Acivity Indicator from hiding when stopAnimating() is called
        myActivityIndicator.hidesWhenStopped = true
        
        myActivityIndicator.backgroundColor = UIColor.clear
        
        view.addSubview(myActivityIndicator)
    }
    
    @IBAction func PostVescle(_ sender: UIButton) {
        
        if (createFileName == "") {
            let alertController = UIAlertController(title: "Error",message: "Please select a photo to post", preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "Ok", style: .default)
            alertController.addAction(actionOk)
            self.present(alertController, animated:true, completion:nil)
            return
        }
        if (timeChosen.text == "Burst Time: Choose Below") {
            let alertController = UIAlertController(title: "Error",message: "Please select a burst time", preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "Ok", style: .default)
            alertController.addAction(actionOk)
            self.present(alertController, animated:true, completion:nil)
            return
        }
        
        let configuration = AWSServiceConfiguration(region:AWSCognitoUserPoolRegion, credentialsProvider:AWSCognitoCredentialsProvider(regionType: AWSCognitoUserPoolRegion, identityPoolId: AWSCognitoIdentityPoolId))
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        myActivityIndicator.startAnimating()
        
        //prepare uploader
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.body = imageURL as URL
        uploadRequest?.key = createFileName
        uploadRequest?.bucket = S3BucketName
        uploadRequest?.contentType = "image/jpeg"
        print(uploadRequest?.body)
        print(uploadRequest?.key)
        print(uploadRequest?.bucket)
        //push to server
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(uploadRequest!).continueWith { (task) -> AnyObject! in
            DispatchQueue.global(qos: .userInitiated).async {
                self.myActivityIndicator.stopAnimating()
            }
            
            if let error = task.error {
                print("Upload failed with error: (\(error.localizedDescription))")
            }
            
            if let exception = task.error {
                print("Upload failed with exception (\(exception))")
            }
            
            if task.result != nil {
                let location = "https://s3.amazonaws.com/" + S3BucketName + "/" + self.createFileName
                let s3URL = NSURL(string: location)
                print("Uploaded to:\n\(s3URL)")
                // Remove locally stored file
                self.remoteImageWithUrl(fileName: (uploadRequest?.key!)!)
                
                //Add to DynamoDB
                let mapper = AWSDynamoDBObjectMapper.default()
                
                let newVescle = Vescles()
                let identity = AWSIdentityManager.default()
                newVescle?._userId = identity.identityId!
                newVescle?._username = identity.userName!
                newVescle?._pictureS3 = self.createFileName
                newVescle?._latitude = String((manager.location?.coordinate.latitude)!)
                newVescle?._longitude = String((manager.location?.coordinate.longitude)!)
                if (self.caption.text?.isEmpty)! {
                    newVescle?._text = "198423cyiqshkfcajkhmz1kaskjdfbhi2ueg01285u"
                } else {
                    newVescle?._text = String(describing: (self.caption.text)!)
                }
                
                
                let tempArr = self.timeChosen.text?.components(separatedBy: " ")
                var expires = 0
                expires += NumberFormatter().number(from: (tempArr?[2])!) as! Int
                let timeType = tempArr?[3]
                if timeType == "Seconds" {
                    expires *= 1000
                } else if timeType == "Minutes" {
                    expires *= 60
                    expires *= 1000
                } else if timeType == "Hours" {
                    expires *= 60
                    expires *= 60
                    expires *= 1000
                } else if timeType == "Days" {
                    expires *= 24
                    expires *= 60
                    expires *= 60
                    expires *= 1000
                } else {
                    print("ERROR RED ALERT RED ALERT RED ALERT")
                    return nil
                }
                
                let expirationTime = expires + getCurrentMillis()
                newVescle?._expiration = String(expirationTime)
                
                // get the current date and time
                let currentDateTime = Date()
                
                // initialize the date formatter and set the style
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .short
                
                // get the date time String from the date object
                newVescle?._posted = String(formatter.string(from: currentDateTime))
                
                
                mapper.save(newVescle!, completionHandler: {(error: Error?) -> Void in
                    if let error = error {
                        print("Amazon DynamoDB Save Error: \(error)")
                        return
                    }
                    print("Item saved.")
                })

            }
            else {
                print("Unexpected empty result.")
            }
            return nil
        }
        
        let alertController = UIAlertController(title: "Wahooooo!",message: "YoU haVe pOsTed a nEw vEsCle", preferredStyle: .alert)
        let actionOk = UIAlertAction(title: "Ok", style: .default) { (action) -> Void in
            let next = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController")
            self.present(next!, animated: true, completion: nil)
        }
        alertController.addAction(actionOk)
        self.present(alertController, animated:true, completion:nil)

        
    }
    
}

class PostVescleControlController: UIViewController, UINavigationControllerDelegate {

    
    @IBOutlet weak var backButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        backButton?.layer.cornerRadius = 10
        
    }
}

class PostVescleControlTextController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIPickerViewDataSource,UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var timeChosen: UILabel!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    var myActivityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpActivityIndicator()
        self.hideKeyboard()
        timePicker.delegate = self
        timePicker.dataSource = self
        textView.delegate = self
        postButton?.layer.cornerRadius = 10
        postButton?.layer.borderColor = UIColor.white.cgColor
        postButton?.layer.borderWidth = 1
        textView.text = "Tap to start crafting ya next sick vescle"
        textView.textColor = UIColor.lightGray
        
    }
    
    func setUpActivityIndicator()
    {
        //Create Activity Indicator
        myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        
        // Position Activity Indicator in the center of the main view
        myActivityIndicator.center = view.center
        
        // If needed, you can prevent Acivity Indicator from hiding when stopAnimating() is called
        myActivityIndicator.hidesWhenStopped = true
        
        myActivityIndicator.backgroundColor = UIColor.clear
        
        view.addSubview(myActivityIndicator)
    }
    
    @IBAction func PostTextVescle(_ sender: UIButton) {
        if (!textView.hasText) {
            let alertController = UIAlertController(title: "Error",message: "Don't send an empty vescle! fill dat ish up", preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "Ok", style: .default)
            alertController.addAction(actionOk)
            self.present(alertController, animated:true, completion:nil)
            return
        }
        if (timeChosen.text == "Burst Time: Choose Below") {
            let alertController = UIAlertController(title: "Error",message: "Please select a burst time", preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "Ok", style: .default)
            alertController.addAction(actionOk)
            self.present(alertController, animated:true, completion:nil)
            return
        }
        
        //Add to DynamoDB
        let mapper = AWSDynamoDBObjectMapper.default()
        
        let newVescle = Vescles()
        let identity = AWSIdentityManager.default()
        newVescle?._userId = identity.identityId!
        newVescle?._username = identity.userName!
        newVescle?._pictureS3 = ProcessInfo.processInfo.globallyUniqueString
        newVescle?._latitude = String((manager.location?.coordinate.latitude)!)
        newVescle?._longitude = String((manager.location?.coordinate.longitude)!)
        newVescle?._text = String(describing: (self.textView.text)!)
        
        let tempArr = self.timeChosen.text?.components(separatedBy: " ")
        var expires = 0
        expires += NumberFormatter().number(from: (tempArr?[2])!) as! Int
        let timeType = tempArr?[3]
        if timeType == "Seconds" {
            expires *= 1000
        } else if timeType == "Minutes" {
            expires *= 60
            expires *= 1000
        } else if timeType == "Hours" {
            expires *= 60
            expires *= 60
            expires *= 1000
        } else if timeType == "Days" {
            expires *= 24
            expires *= 60
            expires *= 60
            expires *= 1000
        } else {
            print("ERROR RED ALERT RED ALERT RED ALERT")
            return
        }
        
        let expirationTime = expires + getCurrentMillis()
        newVescle?._expiration = String(expirationTime)
        
        // get the current date and time
        let currentDateTime = Date()
        
        // initialize the date formatter and set the style
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        
        // get the date time String from the date object
        newVescle?._posted = String(formatter.string(from: currentDateTime))
        
        
        mapper.save(newVescle!, completionHandler: {(error: Error?) -> Void in
            if let error = error {
                print("Amazon DynamoDB Save Error: \(error)")
                return
            }
            print("Item saved.")
        })
    
        
        let alertController = UIAlertController(title: "Wahooooo!",message: "YoU haVe pOsTed a nEw vEsCle", preferredStyle: .alert)
        let actionOk = UIAlertAction(title: "Ok", style: .default) { (action) -> Void in
            let next = self.storyboard?.instantiateViewController(withIdentifier: "MapViewController")
            self.present(next!, animated: true, completion: nil)
        }
        alertController.addAction(actionOk)
        self.present(alertController, animated:true, completion:nil)
        

    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Tap to start crafting ya next sick vescle"
            textView.textColor = UIColor.lightGray
        }
    }
    
    let pickerData = [
        ["1","2","3","4","5","6","7","8","9","10",
         "11","12","13", "14", "15", "16","17","18","19","20",
         "21","22","23", "24", "25", "26","27","28","29","30"],
        ["Seconds","Minutes","Hours","Days"]
    ]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView,numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
    
    func pickerView(_ pickerView: UIPickerView,titleForRow row: Int,forComponent component: Int) -> String? {
        return pickerData[component][row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.white
        pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 18)
        pickerLabel.textAlignment = NSTextAlignment.center
        pickerLabel.text = pickerData[component][row]
        return pickerLabel
    }
    
    //MARK - Instance Methods
    func updateLabel(){
        let time = pickerData[0][timePicker.selectedRow(inComponent: 0)]
        let type = pickerData[1][timePicker.selectedRow(inComponent: 1)]
        timeChosen.text = "Burst Time: " + time + " " + type
    }
    
    func pickerView(_ pickerView: UIPickerView,didSelectRow row: Int,inComponent component: Int)
    {
        updateLabel()
    }

    
}

extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard()
    {
        view.endEditing(true)
    }
}
