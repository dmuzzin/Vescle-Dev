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

class PostVescleViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var timeChosen: UILabel!
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var ImagePicked: UIImageView!
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var cameraButton: UIButton?
    @IBOutlet weak var importButton: UIButton?
    @IBOutlet weak var postButton: UIButton?
    var myActivityIndicator: UIActivityIndicatorView!
    
    let imagePicker = UIImagePickerController()
    var imageURL: NSURL!
    var createFileName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpActivityIndicator()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        imagePicker.delegate = self
        backButton?.layer.cornerRadius = 10
        cameraButton?.layer.cornerRadius = 10
        importButton?.layer.cornerRadius = 10
        postButton?.layer.cornerRadius = 10
        cameraButton?.layer.borderColor = UIColor.white.cgColor
        importButton?.layer.borderColor = UIColor.white.cgColor
        postButton?.layer.borderColor = UIColor.white.cgColor
        cameraButton?.layer.borderWidth = 1
        importButton?.layer.borderWidth = 1
        postButton?.layer.borderWidth = 1
        timePicker.delegate = self
        timePicker.dataSource = self
        
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
    
    //camera stuff
    @IBAction func openCameraButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func openPhotoLibraryButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        ImagePicked.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        ImagePicked.backgroundColor = UIColor.clear
        ImagePicked.contentMode = UIViewContentMode.scaleAspectFit
        
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
    
    @IBAction func PostVescle(_ sender: Any) {
        
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
                
                newVescle?.userId = AWSIdentityManager.default().identityId!
                newVescle?.pictureS3 = location
                newVescle?.latitude = String((manager.location?.coordinate.latitude)!)
                newVescle?.longitude = String((manager.location?.coordinate.longitude)!)
                newVescle?.text = "Placeholder"
                
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
                    expires *= 60
                    expires *= 60
                    expires *= 60
                    expires *= 1000
                } else {
                    print("ERROR RED ALERT RED ALERT RED ALERT")
                    return nil
                }
                
                let expirationTime = expires + getCurrentMillis()
                newVescle?.expiration = String(expirationTime)
                
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



