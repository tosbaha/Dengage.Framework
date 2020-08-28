//
//  DengageEventCollectionService.swift
//  dengage.ios.sdk
//
//  Created by Developer on 21.10.2019.
//  Copyright © 2019 Dengage. All rights reserved.
//

import Foundation
import os.log

internal class EventCollectionService: BaseService {
    
    internal func PostEventCollection(eventCollectionModel: EventCollectionModel) {
        
        let urladdress = EVENT_SERVICE_URL
        
        logger.Log(message: "EVENT_API_URL is %s", logtype: .info, argument: urladdress)
        
        var eventCollectionHttpRequest = EventCollectionHttpRequest()
        eventCollectionHttpRequest.integrationKey = settings.getDengageIntegrationKey()
        eventCollectionHttpRequest.key = eventCollectionModel.key
        eventCollectionHttpRequest.eventTable = eventCollectionModel.eventTable
        eventCollectionHttpRequest.eventDetails = eventCollectionModel.eventDetails

        let parameters = ["integrationKey": eventCollectionHttpRequest.integrationKey,
                          "key": eventCollectionHttpRequest.key,
                          "eventTable": eventCollectionHttpRequest.eventTable,
                          "eventDetails": eventCollectionHttpRequest.eventDetails as Any
            ] as [String: Any]
        
        let queue = DispatchQueue(label: DEVICE_EVENT_QUEUE, qos: .utility)
        
        queue.async {
            self.apiCall(data: parameters, urlAddress: urladdress)
        }
        
        logger.Log(message: "EVENT_COLLECTION_SENT", logtype: .info)
        
    }
    
    internal func SendEvent(table: String, key: String, params: NSDictionary) {
        
        let urladdress = settings.getEventApiUrl()
        
        logger.Log(message: "EVENT_API_URL is %s", logtype: .info, argument: urladdress!)
        
        let integrationKey = settings.getDengageIntegrationKey()
        
        let parameters = ["integrationKey": integrationKey,
                          "key": key,
                          "eventTable": table,
                          "eventDetails":params as Any
            ] as [String: Any]
        
        let queue = DispatchQueue(label: DEVICE_EVENT_QUEUE, qos: .utility)
        
        queue.async {
            self.apiCall(data: parameters, urlAddress: urladdress!)
        }
        
        logger.Log(message: "EVENT_COLLECTION_SENT", logtype: .info)
        
    }
    
}
