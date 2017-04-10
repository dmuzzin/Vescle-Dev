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
    var s3URL: String?
    var expiration_string: String?
    var caption: String?
    var coordinate: CLLocationCoordinate2D
    var posted_string: String?
    init(name:String,lat:CLLocationDegrees,long:CLLocationDegrees,image:String,expiration_time:String,cap:String,posted_time:String){
        title = name
        coordinate = CLLocationCoordinate2DMake(lat, long)
        s3URL = image
        expiration_string = expiration_time
        caption = cap
        posted_string = posted_time
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            if let title = annotation.title! {
                print("Tapped \(title) pin")
            }
        }
    }
}
