
//
//  UserIdentityViewController.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.10
//

import Foundation
import UIKit
import MapKit
import AWSDynamoDB
import CoreData


class Seen: NSManagedObject {
    @NSManaged var s3URL: String
    @NSManaged var expiration: String
    
}


//MARK: Global Declarations
let ann_arbor = CLLocation(latitude: 42.2808, longitude: -83.743);

var username_to_show = String()
var time_remaining_to_show = String()
var imageURL_to_show = String()

//let my_house = bubble(name: "my house", lat: 42.271626, long: -83.738549)

class MapViewController: UIViewController {
    
    //MARK: Properties and Outlets
    let vescle = resizeImage(image: UIImage(named: "vescle")!,
                             targetSize: CGSize.init(width: 50, height: 50))
    
    @IBOutlet weak var mapView: MKMapView!
    
    let regionRadius: CLLocationDistance = 1000
    
    @IBOutlet weak var postButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        if(manager.location != nil) {
            centerMapOnLocation(CLLocation(latitude: (manager.location?.coordinate.latitude)!, longitude: (manager.location?.coordinate.longitude)!))
        } else {
            centerMapOnLocation(ann_arbor)
        }
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 1000
        
        dynamoDBObjectMapper.scan(Vescles.self, expression: scanExpression) .continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> AnyObject! in
            if (task.error == nil) {
                if (task.result != nil) {
                    if let paginatedOutput = task.result {
                        for v in paginatedOutput.items as! [Vescles] {
                            if (Int64(v._expiration!)! >= getCurrentMillis()) {
                                do {
                                    if #available(iOS 10.0, *) {
                                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                        let context = appDelegate.persistentContainer.viewContext
                                        let request = NSFetchRequest<Seen>(entityName: "Seen")
                                        request.predicate = NSPredicate(format: "s3URL == %@", v._pictureS3!)
                                        let fetched = try context.fetch(request)
                                        if fetched.count == 0 {
                                            let new_v = bubble(name: v._username!, lat: Double(v._latitude!)!, long: Double(v._longitude!)!, image: v._pictureS3!, expiration_time: v._expiration!)
                                            self.mapView.addAnnotation(new_v)
                                        }
                                    } else {
                                        // Fallback on earlier versions
                                    }
                                    
                                } catch {
                                    print("There was an error fetching CST Project Details.")
                                }
                            }
                        }
                    }
                }
            }
            else {
                print("Error: \(task.error)")
                
            }
            return nil
        })
        
        //mapView.addAnnotation(my_house)
        
        postButton?.layer.cornerRadius = 20
    }
    
    func centerMapOnLocation(_ location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? bubble{
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.identifier)
            if view == nil {
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotation.identifier)
                view.image = vescle
                view.isEnabled = true
                view.canShowCallout = true
                
                let button = UIButton(type: .custom) as UIButton
                button.frame = CGRect(x: 50, y: 30, width: 50, height: 30)
                button.setBackgroundImage(#imageLiteral(resourceName: "vescle"), for: .normal)
                view.leftCalloutAccessoryView = button
                return view
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if (control == view.leftCalloutAccessoryView) {
            if let annotation = view.annotation as? bubble {
                username_to_show = annotation.title!
                imageURL_to_show = annotation.s3URL!
                time_remaining_to_show = annotation.expiration_string!
                
                do {
                    if #available(iOS 10.0, *) {
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let context = appDelegate.persistentContainer.viewContext
                        let entityDes = NSEntityDescription.entity(forEntityName: "Seen", in: context)
                        let entity = Seen(entity: entityDes!, insertInto: context)
                        entity.s3URL = imageURL_to_show
                        entity.expiration = time_remaining_to_show
                        try context.save()
                    } else {
                        // Fallback on earlier versions
                    }
                    
                } catch {
                    print("There was an error fetching CST Project Details.")
                }

                
                let next = self.storyboard?.instantiateViewController(withIdentifier: "SeeVescleView")
                self.present(next!, animated: true, completion: nil)
            }
            
            
        }
        
    }
}


func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / image.size.width
    let heightRatio = targetSize.height / image.size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
}


