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

class SeeVescleViewController : UIViewController {
    @IBOutlet weak var usernameLabel: UILabel?
    @IBOutlet weak var backToMap: UIButton!
    @IBOutlet weak var userVescle: UIImageView!
    @IBOutlet weak var expirationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel?.text = username_to_show
        var temp_expiration = NumberFormatter().number(from: (time_remaining_to_show)) as! Int64
        temp_expiration -= getCurrentMillis()
        expirationLabel.text = "Time Remaining: \n" + (stringFromTimeInterval(interval: temp_expiration) as String)
        
        backToMap.addTarget(self, action:#selector(self.buttonClicked), for: .touchUpInside)
        
        //get user vescle from s3 and put in userVescle imageView
        
        
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


