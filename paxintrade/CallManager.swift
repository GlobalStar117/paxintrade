import Foundation
import CallKit
import PushKit
import WebRTC

class PushNotificationDelegate: NSObject, PKPushRegistryDelegate {
    weak var callManager: CallManager?

    init(callManager: CallManager) {
        self.callManager = callManager
        super.init()
    }
    
    

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        // Extract the information from the push payload and handle the incoming call
        if type == .voIP {
            
            if let uuidString = payload.dictionaryPayload["uuid"] as? String,
                     let handle = payload.dictionaryPayload["handle"] as? String,
                     let sdpArray = payload.dictionaryPayload["sdp"] as? [[String: Any]],
                     let sdp = sdpArray.first?["sdp"] as? String,
            
                     let action = payload.dictionaryPayload["action"] as? String {
                        let uuid = UUID(uuidString: uuidString)

                        if action == "coming_call" {
                            callManager?.handleIncomingCall(id: uuid, handle: handle, sdpOffer: sdp)
                            
                        } else if action == "rejected" {
                            
                            guard let unwrappedID = uuid else {
                                print("Error: UUID is nil")
                                return
                            }
                            
                            CallManager.shared?.provider.reportCall(with: unwrappedID, endedAt: nil as Date?, reason: .remoteEnded)

                            print("end call")
                        }

                  }

        }
    }

    // Implement the optional method to handle push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // Handle push credentials if needed
    }

    // Implement the optional method to handle push token registration errors
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        // Handle push token invalidation if needed
    }
}

final class CallManager: NSObject, CXProviderDelegate {
    static var shared: CallManager?

    var provider: CXProvider!

    let callController = CXCallController()
    var pushNotificationDelegate: PushNotificationDelegate?
    
    
    

    override init() {
        super.init()
        
        let configuration = CXProviderConfiguration()
        configuration.maximumCallsPerCallGroup = 1
        configuration.maximumCallGroups = 1
        configuration.supportsVideo = true
        let iconImageData = UIImage(named: "pax")?.pngData()
        
        configuration.iconTemplateImageData = iconImageData


        provider = CXProvider(configuration: configuration)

        provider.setDelegate(self, queue: nil)

        // Initialize and set up PushKit
        let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushNotificationDelegate = PushNotificationDelegate(callManager: self)
        pushRegistry.delegate = pushNotificationDelegate
        pushRegistry.desiredPushTypes = [.voIP]

        // Assign the CallManager instance to the shared variable
        CallManager.shared = self
    }

    func handleIncomingCall(id: UUID?, handle: String, sdpOffer: String) {
        
        let Config = Config.default
        let webRTCClient = WebRTCClient(iceServers: Config.webRTCIceServers)

        let sdpOffer = RTCSessionDescription(type: .offer, sdp: sdpOffer)
        webRTCClient.handleIncomingCallWithOffer(sdpOffer: sdpOffer)


        print("Handling incoming call")
        
        guard let unwrappedID = id else {
            print("Error: UUID is nil")
            return
        }
        
        
        reportIncomingCall(id: unwrappedID, handle: handle)
        // Implement your logic to handle incoming calls here
    }
    
    public func reportIncomingCall(id: UUID, handle: String) {
        print("Reporting Call")
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)

        provider.reportNewIncomingCall(with: id, update: update){ error in
            if let error = error {
                print(String(describing: error))
            } else {
                print("Starting session")
            }
        }
    }

    // MARK: - CXProviderDelegate

    func providerDidReset(_ provider: CXProvider) {
        // Implement any necessary actions when the provider is reset
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        // Implement your logic for accepting the call
        action.fulfill()
        print("Call accepted")
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        // Implement your logic for ending the call
        action.fulfill()
        print("Call declined")
    }
}
