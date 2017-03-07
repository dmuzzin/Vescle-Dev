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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel?.text = username_to_show
    }
    
}
