//
//  Settings.swift
//  self.ios.sdk
//
//  Created by Ekin Bulut on 27.11.2019.
//  Copyright © 2019 self. All rights reserved.
//

import Foundation

internal class Settings {

    static let shared = Settings()
    
    let storage: DengageLocalStorage
    let logger: SDKLogger
    
    //MARK: - Variables
    var integrationKey: String = ""
    var token: String? = ""
    var carrierId: String = ""
    var sdkVersion: String
    var advertisingId: String = ""
    var applicationIdentifier : String = ""
    var contactKey: String = ""
    var appVersion: String = ""
    var sessionId: String = ""
    var referrer: String?
    var campSource: String?
    var sendId: String?
    
    var testGroup: String = ""
    
    var badgeCountReset: Bool?
    var permission: Bool?
    var sessionStarted: Bool
    
    var useCloudForSubscription: Bool = false
    var registerForRemoteNotification: Bool = true
    
    init() {
        sdkVersion = SDK_VERSION
        permission = false
        badgeCountReset = true
        storage = DengageLocalStorage.shared
        logger = SDKLogger.shared
        sessionStarted = false
        
    }
    
    init(storage:  DengageLocalStorage = .shared, logger: SDKLogger = .shared){
        
        self.storage = storage
        self.logger = logger
        sdkVersion = SDK_VERSION
        permission = false
        badgeCountReset = true
        sessionStarted = false
    }

    // MARK: -  functions
    func setRegiterForRemoteNotification(enable: Bool)
    {
        self.registerForRemoteNotification = enable
    }
    
    func getRegiterForRemoteNotification() -> Bool {
        
        return self.registerForRemoteNotification
    }
    
    @available(swift, deprecated: 2.5.0)
    func setCloudEnabled(status: Bool) {
        self.useCloudForSubscription = status
    }
    
    func getCloudEnabled() -> Bool {
        
        return self.useCloudForSubscription
    }
    
    func setTestGroup(testGroup: String) {
        
        self.testGroup = testGroup
    }
    
    func getTestGroup() -> String {
        
        return testGroup
    }
    
    func setSessionStart(status: Bool) {
        self.sessionStarted = status
    }
    
    func getSessionStart() -> Bool {
        
        return self.sessionStarted
    }
    
    func setSessionId(sessionId: String) {
        
        self.sessionId = sessionId
    }
    
    func getSessionId() -> String {
        
        return  self.sessionId
    }
    
    func setSdkVersion(sdkVersion: String) {
        
        self.sdkVersion = sdkVersion
    }
    
    func getSdkVersion() -> String {
        
        return self.sdkVersion
    }
    
    func setCarrierId(carrierId: String) {
        
        self.carrierId = carrierId;
    }
    
    func getCarrierId() -> String {
        
        return self.carrierId
    }

    func setAdvertisingId(advertisingId:String) {
        
        self.advertisingId = advertisingId
    }
    
    func getAdvertisinId() -> String? {
        
        return self.advertisingId
    }

    func setApplicationIdentifier(applicationIndentifier: String) {
        
        self.applicationIdentifier = applicationIndentifier
    }
    
    func getApplicationIdentifier() -> String {
        
        return applicationIdentifier;
    }
    
    func setDengageIntegrationKey(integrationKey: String) {
        
        self.integrationKey = integrationKey
    }
    
    func getDengageIntegrationKey() -> String {
        
        return self.integrationKey
    }
    
    func  setBadgeCountReset(badgeCountReset: Bool?) {
        
        self.badgeCountReset = badgeCountReset
    }
    
    func getBadgeCountReset() -> Bool? {
        
        return self.badgeCountReset
    }

    func setContactKey(contactKey: String?) {
        
        self.contactKey = contactKey ?? ""
        storage.setValueWithKey(value: contactKey ?? "", key: "ContactKey")
        self.contactKey = storage.getValueWithKey(key: "ContactKey") ?? ""
    }
    
    func getContactKey() -> String? {
        
        self.contactKey = storage.getValueWithKey(key: "ContactKey") ?? ""
        //        logger.Log(message: "CONTACT_KEY is %s", logtype: .debug, argument: self.contactKey)
        return self.contactKey
    }
    
    func setToken(token: String) {
        
        self.token = token
        storage.setValueWithKey(value: token, key: "Token")
        logger.Log(message:"TOKEN %s", logtype: .debug, argument: self.token!)
        
    }
    
    func getToken() -> String?{
        
        self.token = storage.getValueWithKey(key: "Token")
        return self.token
    }

    func setAppVersion(appVersion: String) {

        self.appVersion = appVersion
    }
    
    func getAppversion() -> String? {
        return self.appVersion
    }
    
    func setPermission(permission: Bool?) {
        self.permission = permission
    }
    
    func getPermission() -> Bool? {
        return self.permission
    }
    
    func getUserAgent() -> String {
        return UAString()
    }
    
    func getEventApiUrl() -> String? {
        var eventUrl = (Bundle.main.object(forInfoDictionaryKey: "DengageEventApiUrl") as? String) ?? ""
        if eventUrl.isEmpty {
            eventUrl = EVENT_SERVICE_URL
        }
        logger.Log(message:"EVENT_API_URL is %s", logtype: .debug, argument: eventUrl)
        return eventUrl
    }
    
    func setChannel(source: String) {
//        storage.setValueWithKey(value: campId, key: "dn_camp_id")
        self.campSource = source
        setCampDate()
        logger.Log(message:"CHANNEL is %s", logtype: .debug, argument: self.campSource ?? "")
    }

    func getChannel()-> String? {
//        return storage.getValueWithKey(key: "dn_camp_id")
        return self.campSource
    }

    func setSendId(sendId: String) {
//        storage.setValueWithKey(value: sendId, key: "dn_send_id")
        self.sendId = sendId
        logger.Log(message:"SEND_ID is %s", logtype: .debug, argument: self.sendId ?? "")
    }

    func getSendId() -> String? {

        return self.sendId
//        return storage.getValueWithKey(key: "dn_send_id")
    }
    
    func setCampDate() {
      
        let date = NSDate() // Get Todays Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let stringDate: String = dateFormatter.string(from: date as Date)
        
        storage.setValueWithKey(value: stringDate, key: "dn_camp_date")
        logger.Log(message:"CampDate is %s", logtype: .debug, argument: stringDate)
    }
    
    func getCampDate() -> NSDate? {
        
        let dateFormatter = DateFormatter()
        // Our date format needs to match our input string format
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let campDate = storage.getValueWithKey(key: "dn_camp_date")
        let dateFromString = dateFormatter.date(from: campDate!)
        
        return dateFromString as NSDate?
    }
    
    func setReferrer(referrer: String) {
        self.referrer = referrer
    }
    
    func getReferrer()-> String? {
        return self.referrer
    }
}
