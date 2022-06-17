
import Foundation
final class InAppMessageManager {
    
    var settings: Settings
    var service: BaseService
    var logger: SDKLogger
    var inAppMessageWindow: UIWindow?
    
    init(settings:Settings, service:BaseService, logger: SDKLogger = .shared){
        self.settings = settings
        self.service = service
        self.logger = logger
        registerLifeCycleTrackers()
    }
}

//MARK: - API
extension InAppMessageManager{
    func fetchInAppMessages(){
        guard shouldFetchInAppMessages else {return}
        let accountName = settings.configuration?.accountName ?? ""
        let request = GetInAppMessagesRequest(accountName: accountName,
                                              contactKey: settings.contactKey.0,
                                              type: settings.contactKey.type,
                                              deviceId: settings.getApplicationIdentifier())
        service.send(request: request) { [weak self] result in
            switch result {
            case .success(let response):
                let nextFetchTime = (Date().timeMiliseconds) + (self?.settings.configuration?.fetchIntervalInMin ?? 0.0)
                DengageLocalStorage.shared.set(value: nextFetchTime, for: .lastFetchedInAppMessageTime)
                self?.addInAppMessagesIfNeeded(response)
            case .failure(let error):
                self?.logger.Log(message: "fetchInAppMessages_ERROR %s", logtype: .debug, argument: error.localizedDescription)
            }
        }
    }
    
    private func markAsInAppMessageAsDisplayed(inAppMessageId: String?) {
        guard isEnabledInAppMessage else {return}
        let accountName = settings.configuration?.accountName ?? ""
        let request = MarkAsInAppMessageDisplayedRequest(type: settings.contactKey.type,
                                                         deviceID: settings.getApplicationIdentifier(),
                                                         accountName: accountName,
                                                         contactKey: settings.contactKey.0,
                                                         id: inAppMessageId ?? "")
        
        service.send(request: request) { [weak self] result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                self?.logger.Log(message: "markAsInAppMessageAsDisplayed_ERROR %s", logtype: .debug, argument: error.localizedDescription)
            }
        }
    }
    
    private func setInAppMessageAsClicked(_ messageId: String?, _ buttonId: String?) {
        guard isEnabledInAppMessage else {return}
        let accountName = settings.configuration?.accountName ?? ""
        let request = MarkAsInAppMessageClickedRequest(type: settings.contactKey.type,
                                                         deviceID: settings.getApplicationIdentifier(),
                                                         accountName: accountName,
                                                         contactKey: settings.contactKey.0,
                                                         id: messageId ?? "",
                                                         buttonId: buttonId)
        
        service.send(request: request) { [weak self] result in
            switch result {
            case .success( _ ):
                self?.removeInAppMessageFromCache(messageId ?? "")
            case .failure(let error):
                self?.logger.Log(message: "setInAppMessageAsClicked_ERROR %s", logtype: .debug, argument: error.localizedDescription)
            }
        }
    }
    
    private func setInAppMessageAsDismissed(_ inAppMessageId: String?) {
        guard isEnabledInAppMessage else {return}
        let accountName = settings.configuration?.accountName ?? ""
        let request = MarkAsInAppMessageAsDismissedRequest(type: settings.contactKey.type,
                                                         deviceID: settings.getApplicationIdentifier(),
                                                         accountName: accountName,
                                                         contactKey: settings.contactKey.0,
                                                         id: inAppMessageId ?? "")
        
        service.send(request: request) { [weak self] result in
            switch result {
            case .success( _ ):
                break
            case .failure(let error):
                self?.logger.Log(message: "setInAppMessageAsDismissed_ERROR %s", logtype: .debug, argument: error.localizedDescription)
            }
        }
    }
}

//MARK: - Workers
extension InAppMessageManager {
    
    func setNavigation(screenName: String? = nil) {
        guard !(settings.inAppMessageShowTime != 0 && Date().timeMiliseconds < settings.inAppMessageShowTime) else {return}
        let messages = DengageLocalStorage.shared.getInAppMessages()
        guard !messages.isEmpty else {return}
        let inAppMessages = InAppMessageUtils.findNotExpiredInAppMessages(untilDate:Date(), messages)
        guard let priorInAppMessage = InAppMessageUtils.findPriorInAppMessage(inAppMessages: inAppMessages, screenName: screenName) else {return}
        showInAppMessage(inAppMessage: priorInAppMessage)
    }
    
    private func showInAppMessage(inAppMessage: InAppMessage) {
        markAsInAppMessageAsDisplayed(inAppMessageId: inAppMessage.data.messageDetails)

        if let showEveryXMinutes = inAppMessage.data.displayTiming.showEveryXMinutes, showEveryXMinutes != 0 {
            var updatedMessage = inAppMessage
            updatedMessage.nextDisplayTime = Date().timeMiliseconds + Double(showEveryXMinutes) * 60000.0
            updateInAppMessageOnCache(updatedMessage)
        } else {
            removeInAppMessageFromCache(inAppMessage.data
                                            .messageDetails ?? "")
        }
        let inappShowTime = (Date().timeMiliseconds) + (self.settings.configuration?.minSecBetweenMessages ?? 0.0)
        DengageLocalStorage.shared.set(value: inappShowTime, for: .inAppMessageShowTime)
        
        let delay = inAppMessage.data.displayTiming.delay ?? 0

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay)) {
            self.showInAppMessageController(with: inAppMessage)
        }
    }
    
    private func showInAppMessageController(with message:InAppMessage){
        switch message.data.content.type {
        case .html:
            guard message.data.content.props.html != nil else {return}
            let controller = InAppMessageHTMLViewController(with: message)
            controller.delegate = self
            self.createInAppWindow(for: controller)
        default:
            break
        }
    }
    
    private func createInAppWindow(for controller: UIViewController){
        let frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        inAppMessageWindow = UIWindow(frame: frame)
        inAppMessageWindow?.rootViewController = controller
        inAppMessageWindow?.windowLevel = UIWindow.Level(rawValue: 2)
        inAppMessageWindow?.makeKeyAndVisible()
    }
    
    private func updateInAppMessageOnCache(_ message: InAppMessage){
        let previousMessages = DengageLocalStorage.shared.getInAppMessages()
        var updatedMessages = previousMessages.filter{$0.data.messageDetails != message.data.messageDetails}
        updatedMessages.append(message)
        DengageLocalStorage.shared.save(updatedMessages)
    }
    
    private func addInAppMessagesIfNeeded(_ messages:[InAppMessage]){
        DispatchQueue.main.async {
        var previousMessages = DengageLocalStorage.shared.getInAppMessages()
        previousMessages.append(contentsOf: messages)
           DengageLocalStorage.shared.save(previousMessages)
        }
    }
    
    private func removeInAppMessageFromCache(_ messageId: String){
        let previousMessages = DengageLocalStorage.shared.getInAppMessages()
        DengageLocalStorage.shared.save(previousMessages.filter{($0.data.messageDetails ?? "") != messageId})
    }
    
    private var isEnabledInAppMessage:Bool{
        guard let config = self.settings.configuration,
              config.accountName != nil else {return false}
        guard config.inAppEnabled else {return false}
        return true
    }
    
    private var shouldFetchInAppMessages:Bool{
        guard isEnabledInAppMessage else {return false}
        guard let lastFetchedTime = settings.lastFetchedInAppMessageTime else {return true}
        guard Date().timeMiliseconds >= lastFetchedTime else {return false}
        return true
    }
    
    private func registerLifeCycleTrackers(){
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func willEnterForeground(){
        fetchInAppMessages()
        settings.removeTokenIfNeeded()
    }
}
//MARK: - InAppMessagesViewController Delegate
extension InAppMessageManager: InAppMessagesActionsDelegate{
    func setTags(tags: [TagItem]) {
        Dengage.setTags(tags)
    }
    
    func open(url: String?) {
        inAppMessageWindow = nil
        guard let urlString = url, let url = URL(string: urlString) else { return }
    //    UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func sendDissmissEvent(messageId: String?) {
        inAppMessageWindow = nil
        setInAppMessageAsDismissed(messageId)
    }
    
    func sendClickEvent(messageId: String?, buttonId:String?) {
        inAppMessageWindow = nil
        setInAppMessageAsClicked(messageId, buttonId)
    }
    
    func promptPushPermission(){
        Dengage.promptForPushNotifications()
    }
    
    func close() {
        inAppMessageWindow = nil
    }
}
