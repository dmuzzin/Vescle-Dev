//
//  Vescle.swift
//  MySampleApp
//
//  Created by Jonathan Sussman on 2/21/17.
//
//

import Foundation
import UIKit
import MapKit
class bubble: NSObject, MKAnnotation{
    var identifier = "bubble"
    var title: String?
    var coordinate: CLLocationCoordinate2D
    init(name:String,lat:CLLocationDegrees,long:CLLocationDegrees){
        title = name
        coordinate = CLLocationCoordinate2DMake(lat, long)
    }
}
