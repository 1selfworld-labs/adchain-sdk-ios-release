//
//  AdchainSDKObjCBridge.swift
//  AdchainSDK
//
//  Objective-C Bridge for React Native integration
//

import Foundation
import UIKit

@objc(AdchainSDKObjCBridge)
public class AdchainSDKObjCBridge: NSObject {
    
    @objc public static let shared = AdchainSDKObjCBridge()
    
    private var loginListener: AdchainSdkLoginListenerWrapper?
    private var offerwallCallback: OfferwallCallbackWrapper?
    
    // MARK: - SDK Initialization
    
    @objc public func initializeSDK(application: UIApplication,
                                    appKey: String,
                                    appSecret: String,
                                    completion: @escaping (Bool, String?) -> Void) {
        let config = AdchainSdkConfig.Builder(appKey: appKey, appSecret: appSecret)
            .setEnvironment(.development)
            .setTimeout(30000)
            .build()
        
        AdchainSdk.shared.initialize(application: application, sdkConfig: config)
        
        // Check initialization status
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true, nil)
        }
    }
    
    // MARK: - Login
    
    @objc public func login(userId: String,
                           gender: String?,
                           birthYear: NSNumber?,
                           completion: @escaping (Bool, String?) -> Void) {
        
        var userGender: AdchainSdkUser.Gender? = nil
        if let genderString = gender {
            switch genderString.lowercased() {
            case "male", "m":
                userGender = .male
            case "female", "f":
                userGender = .female
            default:
                userGender = nil
            }
        }
        
        let user = AdchainSdkUser(
            userId: userId,
            gender: userGender,
            birthYear: birthYear?.intValue
        )
        
        let listener = AdchainSdkLoginListenerWrapper { success, error in
            completion(success, error)
        }
        
        self.loginListener = listener
        
        AdchainSdk.shared.login(adchainSdkUser: user, listener: listener)
    }
    
    @objc public func isLoggedIn() -> Bool {
        return AdchainSdk.shared.isLoggedIn
    }
    
    // MARK: - Quiz
    
    @objc public func loadQuiz(unitId: String,
                               completion: @escaping (Bool, NSArray?) -> Void) {
        let quiz = AdchainQuiz(unitId: unitId)
        
        quiz.load(
            onSuccess: { quizEvents in
                let events = quizEvents.map { event in
                    return [
                        "id": event.id,
                        "title": event.title,
                        "imageUrl": event.imageUrl
                    ]
                }
                completion(true, events as NSArray)
            },
            onFailure: { error in
                completion(false, nil)
            }
        )
    }
    
    // MARK: - Offerwall
    
    @objc public func showOfferwall(from viewController: UIViewController,
                                    completion: @escaping (Bool, String?) -> Void) {
        
        let callback = OfferwallCallbackWrapper(
            onOpened: {
                // Offerwall opened
            },
            onClosed: {
                completion(true, nil)
            },
            onError: { message in
                completion(false, message)
            },
            onRewardEarned: { amount in
                // Handle reward
            }
        )
        
        self.offerwallCallback = callback
        
        AdchainSdk.shared.openOfferwall(presentingViewController: viewController, callback: callback)
    }
}

// MARK: - Wrapper Classes

private final class AdchainSdkLoginListenerWrapper: AdchainSdkLoginListener {
    private let completion: (Bool, String?) -> Void
    
    init(completion: @escaping (Bool, String?) -> Void) {
        self.completion = completion
    }
    
    func onSuccess() {
        completion(true, nil)
    }
    
    func onFailure(_ error: AdchainLoginError) {
        let errorMessage: String
        switch error {
        case .notInitialized:
            errorMessage = "SDK not initialized"
        case .invalidUserId:
            errorMessage = "Invalid user ID"
        case .networkError:
            errorMessage = "Network error"
        case .unknown:
            errorMessage = "Unknown error"
        @unknown default:
            errorMessage = "Unknown error"
        }
        completion(false, errorMessage)
    }
}

private final class OfferwallCallbackWrapper: OfferwallCallback {
    private let onOpenedHandler: () -> Void
    private let onClosedHandler: () -> Void
    private let onErrorHandler: (String) -> Void
    private let onRewardEarnedHandler: (Int) -> Void
    
    init(onOpened: @escaping () -> Void,
         onClosed: @escaping () -> Void,
         onError: @escaping (String) -> Void,
         onRewardEarned: @escaping (Int) -> Void) {
        self.onOpenedHandler = onOpened
        self.onClosedHandler = onClosed
        self.onErrorHandler = onError
        self.onRewardEarnedHandler = onRewardEarned
    }
    
    func onOpened() {
        onOpenedHandler()
    }
    
    func onClosed() {
        onClosedHandler()
    }
    
    func onError(_ message: String) {
        onErrorHandler(message)
    }
    
    func onRewardEarned(_ amount: Int) {
        onRewardEarnedHandler(amount)
    }
}
