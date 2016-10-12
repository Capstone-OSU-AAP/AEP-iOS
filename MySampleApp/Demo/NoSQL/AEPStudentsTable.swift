//
//  AEPStudentsTable.swift
//  MySampleApp
//
//
// Copyright 2016 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.4
//

import Foundation
import UIKit
import AWSDynamoDB
import AWSMobileHubHelper

class AEPStudentsTable: NSObject, Table {
    
    var tableName: String
    var partitionKeyName: String
    var partitionKeyType: String
    var sortKeyName: String?
    var sortKeyType: String?
    var model: AWSDynamoDBObjectModel
    var indexes: [Index]
    var orderedAttributeKeys: [String] {
        return produceOrderedAttributeKeys(model)
    }
    var tableDisplayName: String {

        return "AEP-Students"
    }
    
    override init() {

        model = AEPStudents()
        
        tableName = model.classForCoder.dynamoDBTableName()
        partitionKeyName = model.classForCoder.hashKeyAttribute()
        partitionKeyType = "String"
        indexes = [

            AEPStudentsPrimaryIndex(),

            AEPStudentsDateSorted(),
        ]
        if (model.classForCoder.respondsToSelector("rangeKeyAttribute")) {
            sortKeyName = model.classForCoder.rangeKeyAttribute!()
            sortKeyType = "String"
        }
        super.init()
    }
    
    /**
     * Converts the attribute name from data object format to table format.
     *
     * - parameter dataObjectAttributeName: data object attribute name
     * - returns: table attribute name
     */

    func tableAttributeName(dataObjectAttributeName: String) -> String {
        return AEPStudents.JSONKeyPathsByPropertyKey()[dataObjectAttributeName] as! String
    }
    
    func getItemDescription() -> String {
        return "Find Item with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!) and noteId = \("demo-noteId-500000")."
    }
    
    func getItemWithCompletionHandler(completionHandler: (response: AWSDynamoDBObjectModel?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        objectMapper.load(AEPStudents.self, hashKey: AWSIdentityManager.defaultIdentityManager().identityId!, rangeKey: "demo-noteId-500000", completionHandler: {(response: AWSDynamoDBObjectModel?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func scanDescription() -> String {
        return "Show all items in the table."
    }
    
    func scanWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 5

        objectMapper.scan(AEPStudents.self, expression: scanExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func scanWithFilterDescription() -> String {
        return "Find all items with content < \("demo-content-500000")."
    }
    
    func scanWithFilterWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let scanExpression = AWSDynamoDBScanExpression()
        
        scanExpression.filterExpression = "#content < :content"
        scanExpression.expressionAttributeNames = ["#content": "content" ,]
        scanExpression.expressionAttributeValues = [":content": "demo-content-500000" ,]

        objectMapper.scan(AEPStudents.self, expression: scanExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func insertSampleDataWithCompletionHandler(completionHandler: (errors: [NSError]?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        var errors: [NSError] = []
        let group: dispatch_group_t = dispatch_group_create()
        let numberOfObjects = 20
        

        let itemForGet = AEPStudents()
        
        itemForGet._userId = AWSIdentityManager.defaultIdentityManager().identityId!
        itemForGet._noteId = "demo-noteId-500000"
        itemForGet._content = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("content")
        itemForGet._creationDate = NoSQLSampleDataGenerator.randomSampleNumber()
        itemForGet._title = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("title")
        
        
        dispatch_group_enter(group)
        

        objectMapper.save(itemForGet, completionHandler: {(error: NSError?) -> Void in
            if error != nil {
                dispatch_async(dispatch_get_main_queue(), {
                    errors.append(error!)
                })
            }
            dispatch_group_leave(group)
        })
        
        for _ in 1..<numberOfObjects {

            let item: AEPStudents = AEPStudents()
            item._userId = AWSIdentityManager.defaultIdentityManager().identityId!
            item._noteId = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("noteId")
            item._content = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("content")
            item._creationDate = NoSQLSampleDataGenerator.randomSampleNumber()
            item._title = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("title")
            
            dispatch_group_enter(group)
            
            objectMapper.save(item, completionHandler: {(error: NSError?) -> Void in
                if error != nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        errors.append(error!)
                    })
                }
                dispatch_group_leave(group)
            })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), {
            if errors.count > 0 {
                completionHandler(errors: errors)
            }
            else {
                completionHandler(errors: nil)
            }
        })
    }
    
    func removeSampleDataWithCompletionHandler(completionHandler: (errors: [NSError]?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = ["#userId": "userId"]
        queryExpression.expressionAttributeValues = [":userId": AWSIdentityManager.defaultIdentityManager().identityId!,]

        objectMapper.query(AEPStudents.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), {
                    completionHandler(errors: [error]);
                    })
            } else {
                var errors: [NSError] = []
                let group: dispatch_group_t = dispatch_group_create()
                for item in response!.items {
                    dispatch_group_enter(group)
                    objectMapper.remove(item, completionHandler: {(error: NSError?) -> Void in
                        if error != nil {
                            dispatch_async(dispatch_get_main_queue(), {
                                errors.append(error!)
                            })
                        }
                        dispatch_group_leave(group)
                    })
                }
                dispatch_group_notify(group, dispatch_get_main_queue(), {
                    if errors.count > 0 {
                        completionHandler(errors: errors)
                    }
                    else {
                        completionHandler(errors: nil)
                    }
                })
            }
        }
    }
    
    func updateItem(item: AWSDynamoDBObjectModel, completionHandler: (error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        

        let itemToUpdate: AEPStudents = item as! AEPStudents
        
        itemToUpdate._content = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("content")
        itemToUpdate._creationDate = NoSQLSampleDataGenerator.randomSampleNumber()
        itemToUpdate._title = NoSQLSampleDataGenerator.randomSampleStringWithAttributeName("title")
        
        objectMapper.save(itemToUpdate, completionHandler: {(error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(error: error)
            })
        })
    }
    
    func removeItem(item: AWSDynamoDBObjectModel, completionHandler: (error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        objectMapper.remove(item, completionHandler: {(error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(error: error)
            })
        })
    }
}

class AEPStudentsPrimaryIndex: NSObject, Index {
    
    var indexName: String? {
        return nil
    }
    
    func supportedOperations() -> [String] {
        return [
            QueryWithPartitionKey,
            QueryWithPartitionKeyAndFilter,
            QueryWithPartitionKeyAndSortKey,
            QueryWithPartitionKeyAndSortKeyAndFilter,
        ]
    }
    
    func queryWithPartitionKeyDescription() -> String {
        return "Find all items with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!)."
    }
    
    func queryWithPartitionKeyWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = ["#userId": "userId",]
        queryExpression.expressionAttributeValues = [":userId": AWSIdentityManager.defaultIdentityManager().identityId!,]

        objectMapper.query(AEPStudents.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func queryWithPartitionKeyAndFilterDescription() -> String {
        return "Find all items with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!) and content > \("demo-content-500000")."
    }
    
    func queryWithPartitionKeyAndFilterWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.filterExpression = "#content > :content"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#content": "content",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.defaultIdentityManager().identityId!,
            ":content": "demo-content-500000",
        ]
        

        objectMapper.query(AEPStudents.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func queryWithPartitionKeyAndSortKeyDescription() -> String {
        return "Find all items with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!) and noteId < \("demo-noteId-500000")."
    }
    
    func queryWithPartitionKeyAndSortKeyWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId AND #noteId < :noteId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#noteId": "noteId",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.defaultIdentityManager().identityId!,
            ":noteId": "demo-noteId-500000",
        ]
        

        objectMapper.query(AEPStudents.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func queryWithPartitionKeyAndSortKeyAndFilterDescription() -> String {
        return "Find all items with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!), noteId < \("demo-noteId-500000"), and content > \("demo-content-500000")."
    }
    
    func queryWithPartitionKeyAndSortKeyAndFilterWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.keyConditionExpression = "#userId = :userId AND #noteId < :noteId"
        queryExpression.filterExpression = "#content > :content"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#noteId": "noteId",
            "#content": "content",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.defaultIdentityManager().identityId!,
            ":noteId": "demo-noteId-500000",
            ":content": "demo-content-500000",
        ]
        

        objectMapper.query(AEPStudents.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
}

class AEPStudentsDateSorted: NSObject, Index {
    
    var indexName: String? {

        return "DateSorted"
    }
    
    func supportedOperations() -> [String] {
        return [
            QueryWithPartitionKey,
            QueryWithPartitionKeyAndFilter,
            QueryWithPartitionKeyAndSortKey,
            QueryWithPartitionKeyAndSortKeyAndFilter,
        ]
    }
    
    func queryWithPartitionKeyDescription() -> String {
        return "Find all items with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!)."
    }
    
    func queryWithPartitionKeyWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        

        queryExpression.indexName = "DateSorted"
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.expressionAttributeNames = ["#userId": "userId",]
        queryExpression.expressionAttributeValues = [":userId": AWSIdentityManager.defaultIdentityManager().identityId!,]

        objectMapper.query(AEPStudents.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func queryWithPartitionKeyAndFilterDescription() -> String {
        return "Find all items with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!) and noteId > \("demo-noteId-500000")."
    }
    
    func queryWithPartitionKeyAndFilterWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        

        queryExpression.indexName = "DateSorted"
        queryExpression.keyConditionExpression = "#userId = :userId"
        queryExpression.filterExpression = "#noteId > :noteId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#noteId": "noteId",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.defaultIdentityManager().identityId!,
            ":noteId": "demo-noteId-500000",
        ]
        

        objectMapper.query(AEPStudents.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func queryWithPartitionKeyAndSortKeyDescription() -> String {
        return "Find all items with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!) and creationDate < \(1111500000)."
    }
    
    func queryWithPartitionKeyAndSortKeyWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        

        queryExpression.indexName = "DateSorted"
        queryExpression.keyConditionExpression = "#userId = :userId AND #creationDate < :creationDate"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#creationDate": "creationDate",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.defaultIdentityManager().identityId!,
            ":creationDate": 1111500000,
        ]
        

        objectMapper.query(AEPStudents.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
    
    func queryWithPartitionKeyAndSortKeyAndFilterDescription() -> String {
        return "Find all items with userId = \(AWSIdentityManager.defaultIdentityManager().identityId!), creationDate < \(1111500000), and noteId > \("demo-noteId-500000")."
    }
    
    func queryWithPartitionKeyAndSortKeyAndFilterWithCompletionHandler(completionHandler: (response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let queryExpression = AWSDynamoDBQueryExpression()
        

        queryExpression.indexName = "DateSorted"
        queryExpression.keyConditionExpression = "#userId = :userId AND #creationDate < :creationDate"
        queryExpression.filterExpression = "#noteId > :noteId"
        queryExpression.expressionAttributeNames = [
            "#userId": "userId",
            "#creationDate": "creationDate",
            "#noteId": "noteId",
        ]
        queryExpression.expressionAttributeValues = [
            ":userId": AWSIdentityManager.defaultIdentityManager().identityId!,
            ":creationDate": 1111500000,
            ":noteId": "demo-noteId-500000",
        ]
        

        objectMapper.query(AEPStudents.self, expression: queryExpression, completionHandler: {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completionHandler(response: response, error: error)
            })
        })
    }
}