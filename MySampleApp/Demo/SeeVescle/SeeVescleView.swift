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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel?.text = username_to_show
        backToMap.addTarget(self, action:#selector(self.buttonClicked), for: .touchUpInside)
        
    }
    func buttonClicked() {
        let next = self.storyboard?.instantiateViewController(withIdentifier: "MapView")
        self.present(next!, animated: true, completion: nil)
    }
    
    
    
}
