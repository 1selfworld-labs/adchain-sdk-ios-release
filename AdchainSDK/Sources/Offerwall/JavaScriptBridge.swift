import Foundation
import WebKit

class JavaScriptBridge {
    
    // MARK: - JavaScript Interface Methods (Android @JavascriptInterface 대응)
    
    static func injectBridge(into webView: WKWebView) {
        let bridgeScript = """
        window.AdchainBridge = {
            // Post message to native
            postMessage: function(type, data) {
                var message = {
                    type: type,
                    data: data || {}
                };
                
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.postMessage) {
                    // Now postMessage acts as a function thanks to our wrapper
                    window.webkit.messageHandlers.postMessage(JSON.stringify(message));
                } else {
                    console.error('Native bridge not available');
                }
            },
            
            // Open sub webview
            openWebView: function(url) {
                this.postMessage('openWebView', { url: url });
            },
            
            // Close current webview
            close: function() {
                this.postMessage('close', {});
            },
            
            // Replace current webview
            closeAndOpenWebView: function(url) {
                this.postMessage('closeOpenWebView', { url: url });
            },
            
            // Open external browser
            openExternalBrowser: function(url) {
                this.postMessage('externalOpenBrowser', { url: url });
            },
            
            // Quiz events
            quizStarted: function(quizId) {
                this.postMessage('quizStarted', { quizId: quizId });
            },
            
            quizCompleted: function(quizId, score) {
                this.postMessage('quizCompleted', { quizId: quizId, score: score });
            },
            
            // Mission events
            missionCompleted: function(missionId) {
                this.postMessage('missionCompleted', { missionId: missionId });
            },
            
            // Get user info
            getUserInfo: function(callback) {
                window.userInfoCallback = callback;
                this.postMessage('getUserInfo', {});
            },
            
            // Track event
            trackEvent: function(eventName, parameters) {
                this.postMessage('trackEvent', { eventName: eventName, parameters: parameters });
            }
        };
        
        // Legacy support for webkit.messageHandlers.postMessage
        if (typeof window.webkit === 'undefined') {
            window.webkit = {};
        }
        if (typeof window.webkit.messageHandlers === 'undefined') {
            window.webkit.messageHandlers = {};
        }
        window.webkit.messageHandlers.postMessage = function(message) {
            try {
                var parsed = typeof message === 'string' ? JSON.parse(message) : message;
                window.AdchainBridge.postMessage(parsed.type, parsed.data);
            } catch(e) {
                console.error('Failed to parse message:', e);
            }
        };
        
        console.log('AdchainBridge injected successfully');
        """
        
        webView.evaluateJavaScript(bridgeScript) { _, error in
            if let error = error {
                AdchainLogger.e("JavaScriptBridge", "Failed to inject JavaScript bridge: \(error)", error)
            } else {
                AdchainLogger.d("JavaScriptBridge", "JavaScript bridge injected successfully")
            }
        }
    }
    
    // MARK: - Native to JavaScript Communication
    
    static func sendUserInfo(to webView: WKWebView, user: AdchainSdkUser) {
        let userInfo = [
            "userId": user.userId,
            "gender": user.gender?.rawValue ?? "",
            "birthYear": user.birthYear ?? 0
        ] as [String : Any]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let script = """
            if (window.userInfoCallback) {
                window.userInfoCallback(\(jsonString));
                window.userInfoCallback = null;
            } else if (window.onUserInfoReceived) {
                window.onUserInfoReceived(\(jsonString));
            }
            """
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    AdchainLogger.e("JavaScriptBridge", "Failed to send user info: \(error)", error)
                }
            }
        }
    }
    
    static func notifyRewardEarned(to webView: WKWebView, amount: Int) {
        let script = """
        if (window.onRewardEarned) {
            window.onRewardEarned(\(amount));
        }
        """
        
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                AdchainLogger.e("JavaScriptBridge", "Failed to notify reward: \(error)", error)
            }
        }
    }
    
    static func executeJavaScript(_ script: String, in webView: WKWebView, completion: ((Any?, Error?) -> Void)? = nil) {
        webView.evaluateJavaScript(script) { result, error in
            completion?(result, error)
        }
    }
}