//
//  SeeVescleView.swift
//  MySampleApp
//
//  Created by Jonathan Sussman on 3/7/17.
//
//

import Foundation
import UIKit
import MapKit
import AWSDynamoDB
import AWSS3

class SeeVescleViewController : UIViewController {
    @IBOutlet weak var usernameLabel: UILabel?
    @IBOutlet weak var backToMap: UIButton!
    @IBOutlet weak var userVescle: UIImageView!
    @IBOutlet weak var caption: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel?.text = username_to_show
        
        backToMap.addTarget(self, action:#selector(self.buttonClicked), for: .touchUpInside)
        
        let transferManager = AWSS3TransferManager.default()
        let downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("vescle.jpg")
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        print(S3BucketName)
        downloadRequest?.bucket = S3BucketName
        downloadRequest?.key = imageURL_to_show
        print(imageURL_to_show)
        downloadRequest?.downloadingFileURL = downloadingFileURL
        
        transferManager.download(downloadRequest!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask<AnyObject>) -> Any? in
            
            if let error = task.error as? NSError {
                if error.domain == AWSS3TransferManagerErrorDomain, let code = AWSS3TransferManagerErrorType(rawValue: error.code) {
                    switch code {
                    case .cancelled, .paused:
                        break
                    default:
                        print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                    }
                } else {
                    print("Error downloading: \(downloadRequest?.key) Error: \(error)")
                }
                return nil
            }
            print("Download complete for: \(downloadRequest?.key)")
            //let downloadOutput = task.result
            self.userVescle.image = UIImage(contentsOfFile: downloadingFileURL.path)
            self.caption.text = caption_to_show
            return nil
        })
        
    }
    func buttonClicked() {
        let next = self.storyboard?.instantiateViewController(withIdentifier: "MapView")
        self.present(next!, animated: true, completion: nil)
    }
    
    func stringFromTimeInterval(interval: Int64) -> NSString {
        
        var ti = NSInteger(interval)
        ti /= 1000
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        let days = (ti / 3600) / 24
        
        return NSString(format: "%0.2d days %0.2d hrs %0.2d mins %0.2d secs",days,hours,minutes,seconds)
    }
    
}


