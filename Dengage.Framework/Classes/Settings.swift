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

    // MARK: - Variables
    var integrationKey: String = ""
    var token: String? = ""
    var carrierId: String = ""
    var sdkVersion: String
    var advertisingId: String = ""
    var applicationIdentifier: String = ""
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
    var disableOpenURL:Bool = false
    
    var shouldFetchFromAPI:Bool{
        guard let date = lastFetchedDate else { return true}
        if let diff = Calendar.current.dateComponents([.minute], from: date, to: Date()).minute, diff > 10 {
            return true
        }
        return false
    }
    
    var lastFetchedDate:Date?
    
    var configuration: GetSDKParamsResponse?{
        return storage.getConfig()
    }
    
    var lastFetchedInAppMessageTime:Double? {
        storage.getValue(for: .lastFetchedInAppMessageTime) as? Double
    }
    
    var inAppMessageShowTime:Double{
        (storage.getValue(for: .inAppMessageShowTime) as? Double) ?? 0
    }

    init(storage: DengageLocalStorage = .shared, logger: SDKLogger = .shared) {

        self.storage = storage
        self.logger = logger
        sdkVersion = SDK_VERSION
        permission = false
        badgeCountReset = true
        sessionStarted = false
        initServiceAPIs()
    }

    // MARK: - functions
    func initServiceAPIs(){
        EVENT_SERVICE_URL = getEventApiUrl()
        SUBSCRIPTION_SERVICE_URL = getSubscriptionApi()
    }
    
    func setRegiterForRemoteNotification(enable: Bool) {
        self.registerForRemoteNotification = enable
    }

    func getRegiterForRemoteNotification() -> Bool {
        return self.registerForRemoteNotification
    }

    @available(swift, deprecated: 2.5.0)
    func setCloudEnabled(status: Bool) {
        self.useCloudForSubscription = status
    }

    @available(swift, deprecated: 2.5.0)
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
        self.carrierId = carrierId
    }

    func getCarrierId() -> String {
        return self.carrierId
    }

    func setAdvertisingId(advertisingId: String) {
        self.advertisingId = advertisingId
    }

    func getAdvertisinId() -> String? {
        return self.advertisingId
    }

    var contactKey:(String, type:String){
        let key = getContactKey() ?? getApplicationIdentifier()
        let type = getContactKey() != nil ? "c" : "d"
        return (key, type)
    }
    /// ApplicationIdentifier can be set by api user or generated by sdk.
    /// - Parameter applicationIdentifier : Udid
    func setApplicationIdentifier(applicationIndentifier: String) {
        storage.set(value: applicationIndentifier, for: .applicationIdentifier)
        self.applicationIdentifier = applicationIndentifier
    }

    func getApplicationIdentifier() -> String {
        return applicationIdentifier
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
        let previous = getContactKey()
        if previous != contactKey {
            let newKey = (contactKey?.isEmpty ?? true) ? nil : contactKey
            storage.set(value: newKey, for: .contactKey)
            Dengage.syncSubscription()
        }
    }

    func getContactKey() -> String? {
        storage.getValue(key: .contactKey)
    }

    func setToken(token: String) {
        let previous = getToken()
        if previous != token {
            self.token = token
            storage.set(value: token, for: .token)
            logger.Log(message: "TOKEN %s", logtype: .debug, argument: self.token!)
            Dengage.syncSubscription()
        }
    }

    func getToken() -> String? {
        self.token = storage.getValue(key: .token)
        return self.token
    }

    internal func removeTokenIfNeeded() {
        let current = UNUserNotificationCenter.current()

        current.getNotificationSettings(completionHandler: { [weak self] (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                DispatchQueue.main.async {
                    self?.logger.Log(message: "REGISTER_TOKEN", logtype: .debug)
                    UIApplication.shared.registerForRemoteNotifications()
                }
            default:
                self?.setToken(token: "")
            }
        })
    }
    func setAppVersion(appVersion: String) {

        self.appVersion = appVersion
    }

    func getAppversion() -> String? {
        return self.appVersion
    }

    func setPermission(permission: Bool?) {
        let previous = getPermission()
        if previous != permission {
            storage.set(value: permission, for: .userPermission)
            self.permission = permission
            Dengage.syncSubscription()
        }
    }

    func getPermission() -> Bool? {
        return storage.getValue(for: .userPermission) as? Bool
    }

    func getUserAgent() -> String {
        return UAString()
    }

    func getEventApiUrl() -> String {
        guard let eventUrl = Bundle.main.object(forInfoDictionaryKey: "DengageEventApiUrl") as? String else { return EVENT_SERVICE_URL }
        logger.Log(message: "EVENT_API_URL is %s", logtype: .debug, argument: eventUrl)
        return eventUrl
    }

    func setChannel(source: String) {
        self.campSource = source
        setCampDate()
        logger.Log(message: "CHANNEL is %s", logtype: .debug, argument: self.campSource ?? "")
    }

    func getChannel() -> String? {
        return self.campSource
    }

    func setSendId(sendId: String) {
        self.sendId = sendId
        logger.Log(message: "SEND_ID is %s", logtype: .debug, argument: self.sendId ?? "")
    }

    func getSendId() -> String? {
        return self.sendId
    }

    func setCampDate() {
        let date = NSDate() // Get Todays Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let stringDate: String = dateFormatter.string(from: date as Date)

        storage.set(value: stringDate, for: .campDate)
        logger.Log(message: "CampDate is %s", logtype: .debug, argument: stringDate)
    }

    func getCampDate() -> NSDate? {
        let dateFormatter = DateFormatter()
        // Our date format needs to match our input string format
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let campDate = storage.getValue(key: .campDate)
        let dateFromString = dateFormatter.date(from: campDate!)

        return dateFromString as NSDate?
    }

    func setReferrer(referrer: String) {
        self.referrer = referrer
    }

    func getReferrer() -> String? {
        return self.referrer
    }

    func getSubscriptionApi() -> String {
        guard let dengageApiUrl = Bundle.main.object(forInfoDictionaryKey: "DengageApiUrl") as? String else { return SUBSCRIPTION_SERVICE_URL }
        return dengageApiUrl
    }

    func getLanguage() -> String {
        return Locale.current.languageCode ?? ""
    }

    func getTimeZone() -> String {
        return TimeZone.current.abbreviation() ?? ""
    }

    func getDeviceCountry() -> String {
        guard let regionCode = Locale.current.regionCode else { return "" }
        let countryId = Locale.identifier(fromComponents: [NSLocale.Key.countryCode.rawValue: regionCode])
        guard let countryName = NSLocale(localeIdentifier: "en_US").displayName(forKey: NSLocale.Key.identifier, value: countryId) else { return "" }
        return countryName
    }
}
