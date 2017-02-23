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

class PostVescleViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var TimePicker: UIPickerView!
    @IBOutlet weak var ImagePicked: UIImageView!
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var cameraButton: UIButton?
    @IBOutlet weak var importButton: UIButton?
    @IBOutlet weak var postButton: UIButton?
    
    let imagePicker = UIImagePickerController()
    var imageURL = NSURL()
    var filename = ""

    override func viewDidLoad() {
        super.viewDidLoad()
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
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            ImagePicked.contentMode = .scaleAspectFit
            ImagePicked.image = pickedImage
            
            if let referenceUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {
                
                ALAssetsLibrary().asset(for: referenceUrl as URL!, resultBlock: { asset in
                    
                    self.filename = (asset?.defaultRepresentation().filename())!
                    //do whatever with your file name
                    
                }, failureBlock: nil)
            }
            imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        
        
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func PostVescle(_ sender: Any) {
        let configuration = AWSServiceConfiguration(region:AWSCognitoUserPoolRegion, credentialsProvider:AWSCognitoCredentialsProvider(regionType: AWSCognitoUserPoolRegion, identityPoolId: AWSCognitoUserPoolId))
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        if (filename == "") {
            let alertController = UIAlertController(title: "Post Error", message: "Picture needs to be selected", preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "OK",
                                         style: .default,
                                         handler: nil) //You can use a block here to handle a press on this button
            
            alertController.addAction(actionOk)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        let ext = "JPG"
        //let imageURL = info[UIImagePickerControllerReferenceURL] as NSURL
        //let imageURL = Bundle.main.url(forResource: filename, withExtension: "")
        
        //prepare uploader
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.body = imageURL as URL
        uploadRequest?.key = ProcessInfo.processInfo.globallyUniqueString + "." + ext
        uploadRequest?.bucket = S3BucketName
        uploadRequest?.contentType = "image/" + ext
        
        //push to server
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(uploadRequest!).continueWith { (task) -> AnyObject! in
            if let error = task.error {
                print("Upload failed ❌ (\(error))")
            }
            if task.result != nil {
                let s3URL = NSURL(string: "http://s3.amazonaws.com/\(S3BucketName)/\(uploadRequest?.key!)")!
                print("Uploaded to:\n\(s3URL)")
            }
            else {
                print("Unexpected empty result.")
            }
            return nil
        }

        
    }
    
}

class TimePickerView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
    var day:Int = 0
    var hour:Int = 0
    var minute:Int = 0
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    func setup(){
        self.delegate = self
        self.dataSource = self
        
        let height = CGFloat(20)
         let offsetX = self.frame.size.width/1.5
         let offsetX2 = self.frame.size.width/3
         let offsetY = self.frame.size.height/2 - height/2
         let marginX = CGFloat(42)
         let width = offsetX - marginX
        
        
        let dayLabel = UILabel(frame: CGRect(x: marginX, y: offsetY, width: width, height: height))
        dayLabel.text = "day"
        self.addSubview(dayLabel)
        
        let hourLabel = UILabel(frame: CGRect(x: marginX+offsetX2, y: offsetY, width: width, height: height))
         hourLabel.text = "hour"
         self.addSubview(hourLabel)
         
        let minsLabel = UILabel(frame: CGRect(x: marginX + offsetX, y: offsetY, width: width, height: height))
         minsLabel.text = "min"
         self.addSubview(minsLabel)
        
    }
    
    func getDate() -> NSDate{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "DD days HH hours mm minutes"
        let date = dateFormatter.date(from: String(format: "%02d", self.day) + " days " + String(format: "%02d", self.hour) + " hours " + String(format: "%02d", self.minute) + " minutes")
        return date! as NSDate
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            self.day = row
        case 1:
            self.hour = row
        case 2:
            self.minute = row
        default:
            print("No component with number \(component)")
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 24
        }
        
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if (view != nil) {
            (view as! UILabel).text = String(format:"%02lu", row)
            return view!
        }
        let columnView = UILabel(frame: CGRect(x: 35, y: 0, width: self.frame.size.width/3 - 35, height: 30))
        columnView.text = String(format:"%02lu", row)
        columnView.textAlignment = NSTextAlignment.center
        
        return columnView
    }
    
}



