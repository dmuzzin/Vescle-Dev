//
//  Vescles.swift
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
import AWSDynamoDB

class Vescles: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _userId:String?
    var _username:String?
    var _pictureS3:String?
    var _text:String?
    var _longitude:String?
    var _latitude:String?
    var _expiration:String?
    
    class func dynamoDBTableName() -> String {
        return "vescle-mobilehub-81544248-Vescles"
    }
    
    class func hashKeyAttribute() -> String {
        return "_userId"
    }
    
    class func rangeKeyAttribute() -> String {
        return "_pictureS3"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
            "_userId" : "userId",
            "_pictureS3" : "pictureS3",
            "_expiration" : "expiration",
            "_latitude" : "latitude",
            "_longitude" : "longitude",
            "_text" : "text",
        ]
    }
}
