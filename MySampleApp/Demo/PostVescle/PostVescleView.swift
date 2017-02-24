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

class PostVescleViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var TimePicker: UIPickerView!
    @IBOutlet weak var ImagePicked: UIImageView!
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var cameraButton: UIButton?
    @IBOutlet weak var importButton: UIButton?
    @IBOutlet weak var postButton: UIButton?
    var myActivityIndicator: UIActivityIndicatorView!
    
    let imagePicker = UIImagePickerController()
    var imageURL: NSURL!

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
        imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        
        ImagePicked.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        ImagePicked.backgroundColor = UIColor.clear
        ImagePicked.contentMode = UIViewContentMode.scaleAspectFit
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
        let configuration = AWSServiceConfiguration(region:AWSCognitoUserPoolRegion, credentialsProvider:AWSCognitoCredentialsProvider(regionType: AWSCognitoUserPoolRegion, identityPoolId: AWSCognitoIdentityPoolId))
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        var localFileName:String?
        
        if let imageToUploadUrl = imageURL
        {
            let phResult = PHAsset.fetchAssets(withALAssetURLs: [imageURL as URL], options: nil)
            localFileName = phResult.firstObject?.originalFilename
        }
        
        if localFileName == nil
        {
            let alertController = UIAlertController(title: "Post Error",message: "Picture needs to be selected", preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(actionOk)
            self.present(alertController, animated:true, completion:nil)
            return
        }
        
        myActivityIndicator.startAnimating()
        let remoteName = localFileName!
        
        //prepare uploader
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.body = generateImageUrl(fileName: remoteName) as URL
        uploadRequest?.key = remoteName
        let s3KeyValue = remoteName
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
                let location = "https://s3.amazonaws.com/" + S3BucketName + "/" + s3KeyValue
                let s3URL = NSURL(string: location)
                print("Uploaded to:\n\(s3URL)")
                // Remove locally stored file
                self.remoteImageWithUrl(fileName: (uploadRequest?.key!)!)
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
         let offsetX = self.frame.size.width/3
         let offsetY = self.frame.size.height/2 - height/2
         let marginX = CGFloat(42)
         let width = offsetX - marginX
        
        
        let dayLabel = UILabel(frame: CGRect(x: marginX + 15, y: offsetY, width: width, height: height))
        dayLabel.text = "days"
        self.addSubview(dayLabel)
        
        let hourLabel = UILabel(frame: CGRect(x: marginX+120, y: offsetY, width: width, height: height))
         hourLabel.text = "hrs"
         self.addSubview(hourLabel)
         
        let minsLabel = UILabel(frame: CGRect(x: marginX+210, y: offsetY, width: width, height: height))
         minsLabel.text = "mins"
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
        if component == 0  {
            return 7
        }
        if component == 1 {
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
        let columnView = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.size.width/3, height: 30))
        columnView.text = String(format:"%02lu", row)
        columnView.textAlignment = NSTextAlignment.center
        
        return columnView
    }
    
}



