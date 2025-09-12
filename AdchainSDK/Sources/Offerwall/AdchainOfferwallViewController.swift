import UIKit
import WebKit

class AdchainOfferwallViewController: UIViewController {
    // MARK: - Static Properties (Android와 동일한 WebView Stack 관리)
    private static var webViewStack = [Weak<AdchainOfferwallViewController>]()
    private static var callback: OfferwallCallback?
    
    // MARK: - Properties
    private var webView: WKWebView!
    var baseUrl: String?
    var userId: String?
    var appKey: String?
    private var isSubWebView = false
    internal var contextType = "offerwall"
    internal var quizId: String?
    internal var quizTitle: String?
    private var advertisingId: String?
    
    // MARK: - Static Methods
    static func setCallback(_ cb: OfferwallCallback?) {
        callback = cb
    }
    
    internal static func openSubWebView(from parent: UIViewController, url: String) {
        let subVC = AdchainOfferwallViewController()
        subVC.baseUrl = url
        subVC.isSubWebView = true
        subVC.userId = AdchainSdk.shared.getCurrentUser()?.userId
        subVC.appKey = AdchainSdk.shared.getConfig()?.appKey
        subVC.modalPresentationStyle = .fullScreen
        
        parent.present(subVC, animated: true)
    }
    
    internal static func closeAllWebViews() {
        // Close all stacked WebViews (Android와 동일)
        while !webViewStack.isEmpty {
            if let weakRef = webViewStack.popLast(),
               let vc = weakRef.value {
                vc.dismiss(animated: false)
            }
        }
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set background color to match WebView background (#f5f6f7)
        //view.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 247/255, alpha: 1.0)
        view.backgroundColor = UIColor.white
        
        // Add to stack if sub WebView
        if isSubWebView {
            Self.webViewStack.append(Weak(self))
        }
        
        // Setup WebView
        setupWebView()
        
        // Get base URL
        guard let baseUrl = baseUrl, !baseUrl.isEmpty else {
            print("No base URL provided")
            if !isSubWebView {
                Self.callback?.onError("Failed to load offerwall: No URL provided")
            }
            dismiss(animated: true)
            return
        }
        
        // For sub WebView, load immediately
        if isSubWebView {
            if let url = URL(string: baseUrl) {
                let request = URLRequest(url: url)
                webView.load(request)
            }
            return
        }
        
        // For main WebView, get advertising ID first then load
        Task {
            // Get advertising ID
            advertisingId = await DeviceUtils.getAdvertisingId()
            
            // Build URL with advertising ID
            let finalUrl = buildOfferwallUrl(baseUrl)
            print("Loading offerwall URL: \(finalUrl)")
            
            await MainActor.run {
                if let url = URL(string: finalUrl) {
                    var request = URLRequest(url: url)
                    
                    // Add custom headers
                    if let appKey = appKey {
                        request.setValue(appKey, forHTTPHeaderField: "x-adchain-app-key")
                    }
                    if let userId = userId {
                        request.setValue(userId, forHTTPHeaderField: "x-adchain-user-id")
                    }
                    if let advertisingId = advertisingId, !advertisingId.isEmpty {
                        request.setValue(advertisingId, forHTTPHeaderField: "x-adchain-advertising-id")
                    }
                    
                    webView.load(request)
                }
            }
        }
    }
    
    // MARK: - WebView Setup
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        
        // JavaScript 설정
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // User Agent 설정 (로드 전에 설정)
        let version = getSDKVersion()
        config.applicationNameForUserAgent = " AdchainSDK/\(version)"
        
        // Message Handler 등록 - 웹페이지가 요구하는 여러 이름들 등록
        let contentController = WKUserContentController()
        contentController.add(self, name: "adchainNative")
        
        
        // JavaScript Polyfill - 프로토타입 체인을 활용한 안정적인 방법
        let jsPolyfill = """
        (function () {
          var mh = window.webkit && window.webkit.messageHandlers;
          if (!mh) return;

          function _bridge(msg) {
            try {
              var s = (typeof msg === 'string') ? msg : JSON.stringify(msg);
              // 표준화된 단일 네이티브 핸들러 사용
              window.webkit.messageHandlers.adchainNative.postMessage(s);
            } catch (e) {
              console.error('[AdchainSDK] bridge error', e);
            }
          }

          try {
            var proto = Object.getPrototypeOf(mh) || Object.prototype;
            Object.defineProperty(proto, 'postMessage', {
              configurable: true,
              get: function () {
                // messageHandlers에서만 함수 반환
                return (this === mh) ? _bridge : undefined;
              }
            });
            console.log('[AdchainSDK] Polyfill installed on prototype');
          } catch (e) {
            // 폴백: Object.prototype에 동일한 가드로 getter 설치
            try {
              Object.defineProperty(Object.prototype, 'postMessage', {
                configurable: true,
                get: function () {
                  var _mh = window.webkit && window.webkit.messageHandlers;
                  return (this === _mh) ? _bridge : undefined;
                }
              });
              console.log('[AdchainSDK] Polyfill installed on Object.prototype (fallback)');
            } catch (_) {
              console.error('[AdchainSDK] Failed to install polyfill');
            }
          }
        })();
        """
        
        // WKUserScript로 문서 시작 시점에 주입
        let userScript = WKUserScript(
            source: jsPolyfill,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(userScript)
        
        config.userContentController = contentController
        
        // Create WebView
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Set WebView background color to match the view background (#f5f6f7)
        //let backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 247/255, alpha: 1.0)
        let backgroundColor = UIColor.white
        webView.backgroundColor = backgroundColor
        webView.isOpaque = false
        webView.scrollView.backgroundColor = backgroundColor
        
        // Safe Area를 존중하도록 설정
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        
        view.addSubview(webView)
        
        // Safe Area Layout Guide에 맞춰 constraints 설정
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - URL Building
    private func buildOfferwallUrl(_ baseUrl: String) -> String {
        var components = URLComponents(string: baseUrl)!
        
        // Preserve existing query parameters from the original URL
        var queryItems = components.queryItems ?? [URLQueryItem]()
        
        // User and app info (also in headers)
        queryItems.append(URLQueryItem(name: "user_id", value: userId ?? ""))
        queryItems.append(URLQueryItem(name: "app_key", value: appKey ?? ""))
        
        // Add IFA (advertising ID) if available
        if let advertisingId = advertisingId, !advertisingId.isEmpty {
            queryItems.append(URLQueryItem(name: "ifa", value: advertisingId))
        }
        
        // Add quiz-specific parameters if context is quiz
        if contextType == "quiz" {
            if let quizId = quizId {
                queryItems.append(URLQueryItem(name: "quiz_id", value: quizId))
            }
            if let quizTitle = quizTitle {
                queryItems.append(URLQueryItem(name: "quiz_title", value: quizTitle))
            }
            queryItems.append(URLQueryItem(name: "context", value: "quiz"))
        }
        
        // Device info (reduced set)
        queryItems.append(URLQueryItem(name: "device_id", value: DeviceUtils.getDeviceId()))
        queryItems.append(URLQueryItem(name: "platform", value: "iOS"))
        
        // SDK info (only version)
        let sdkVersion = getSDKVersion()
        queryItems.append(URLQueryItem(name: "sdk_version", value: sdkVersion))
        
        // Session info
        queryItems.append(URLQueryItem(name: "session_id", value: NetworkManager.shared.getSessionId()))
        queryItems.append(URLQueryItem(name: "timestamp", value: "\(Int(Date().timeIntervalSince1970 * 1000))"))
        
        components.queryItems = queryItems
        
        // Also inject IFA via JavaScript for backward compatibility
        if let advertisingId = advertisingId, !advertisingId.isEmpty {
            Task {
                let jsCode = "if(window.AdchainConfig) { window.AdchainConfig.ifa = '\(advertisingId)'; }"
                _ = try? await webView.evaluateJavaScript(jsCode)
            }
        }
        
        return components.url!.absoluteString
    }
    
    // MARK: - Close Methods
    private func closeOfferwall() {
        print("Closing offerwall")
        
        // If sub WebView, just close this one
        if isSubWebView {
            dismiss(animated: true)
            return
        }
        
        // Close all WebViews
        Self.closeAllWebViews()
        Self.callback?.onClosed()
        
        // Track close event
        Task {
            _ = try? await NetworkManager.shared.trackEvent(
                userId: userId ?? "",
                eventName: "offerwall_closed",
                sdkVersion: AdchainSdk.shared.getSDKVersion(),
                category: "offerwall"
            )
        }
        
        dismiss(animated: true)
    }
    
    // MARK: - Status Bar Configuration
    override var prefersStatusBarHidden: Bool {
        return false  // Show status bar for better UX
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent  // Dark text for white background
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove from stack if sub WebView
        if isSubWebView {
            Self.webViewStack.removeAll { $0.value == self }
        }
        
        // Clear callback for main WebView
        if !isSubWebView {
            Self.callback = nil
        }
    }
}

// MARK: - WKScriptMessageHandler (JavaScript Bridge)
extension AdchainOfferwallViewController: WKScriptMessageHandler {
    private func getSDKVersion() -> String {
        // AdchainSdk의 중앙화된 버전 정보 사용
        return AdchainSdk.shared.getSDKVersion()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Handle messages from any of the registered handler names
        guard ["adchainNative", "AdChain", "AdchainBridge"].contains(message.name) else { return }
        
        if let jsonString = message.body as? String {
            print("Received webkit message from \(message.name): \(jsonString)")
            handlePostMessage(jsonString)
        }
    }
    
    // MARK: - Message Handler (Android의 handlePostMessage와 완전 동일)
    private func handlePostMessage(_ jsonMessage: String) {
        guard let data = jsonMessage.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            print("Failed to parse JS message")
            return
        }
        
        let messageData = json["data"] as? [String: Any]
        
        print("Processing message type: \(type)")
        
        switch type {
        case "openWebView":
            handleOpenWebView(data: messageData)
        case "close":
            handleClose()
        case "closeOpenWebView":
            handleCloseOpenWebView(data: messageData)
        case "externalOpenBrowser":
            handleExternalOpenBrowser(data: messageData)
        case "quizCompleted":
            if contextType == "quiz" {
                handleQuizCompleted(data: messageData)
            }
        case "quizStarted":
            if contextType == "quiz" {
                handleQuizStarted(data: messageData)
            }
        case "missionCompleted":
            handleMissionCompleted(data: messageData)
        case "getUserInfo":
            handleGetUserInfo()
        default:
            print("Unknown message type: \(type)")
        }
    }
    
    // MARK: - Individual Message Handlers
    private func handleOpenWebView(data: [String: Any]?) {
        guard let url = data?["url"] as? String, !url.isEmpty else {
            print("openWebView: No URL provided")
            return
        }
        
        print("Opening sub WebView: \(url)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            Self.openSubWebView(from: self, url: url)
        }
        
        Task {
            _ = try? await NetworkManager.shared.trackEvent(
                userId: userId ?? "",
                eventName: "sub_webview_opened",
                sdkVersion: AdchainSdk.shared.getSDKVersion(),
                category: "offerwall",
                properties: ["url": url]
            )
        }
    }
    
    private func handleClose() {
        print("Handling close message")
        
        DispatchQueue.main.async { [weak self] in
            // Close all WebViews
            Self.closeAllWebViews()
            
            // Close main offerwall
            if self?.isSubWebView == false {
                Self.callback?.onClosed()
            }
            
            self?.dismiss(animated: true)
        }
    }
    
    private func handleCloseOpenWebView(data: [String: Any]?) {
        guard let url = data?["url"] as? String, !url.isEmpty else {
            print("closeOpenWebView: No URL provided")
            return
        }
        
        print("Handling closeOpenWebView - isSubWebView: \(isSubWebView), url: \(url)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create new ViewController
            let newVC = AdchainOfferwallViewController()
            newVC.baseUrl = url
            newVC.isSubWebView = true
            newVC.userId = self.userId
            newVC.appKey = self.appKey
            newVC.modalPresentationStyle = .fullScreen
            newVC.modalTransitionStyle = .crossDissolve
            
            // Android와 동일한 방식: 먼저 dismiss 후 새로 present
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: false) {
                    presentingVC.present(newVC, animated: true)
                }
            }
            
            Task {
                _ = try? await NetworkManager.shared.trackEvent(
                    userId: self.userId ?? "",
                    eventName: "webview_replaced",
                    sdkVersion: AdchainSdk.shared.getSDKVersion(),
                    category: "offerwall",
                    properties: ["url": url]
                )
            }
        }
    }
    
    private func handleExternalOpenBrowser(data: [String: Any]?) {
        guard let urlString = data?["url"] as? String,
              let url = URL(string: urlString) else {
            print("externalOpenBrowser: No URL provided")
            return
        }
        
        print("Opening external browser: \(urlString)")
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                
                Task {
                    _ = try? await NetworkManager.shared.trackEvent(
                        userId: self.userId ?? "",
                        eventName: "external_browser_opened",
                        sdkVersion: AdchainSdk.shared.getSDKVersion(),
                        category: "offerwall",
                        properties: ["url": urlString]
                    )
                }
            } else {
                print("Cannot open URL: \(urlString)")
            }
        }
    }
    
    // Quiz-specific handlers
    private func handleQuizCompleted(data: [String: Any]?) {
        print("Quiz completed")
        
        DispatchQueue.main.async { [weak self] in
            Task {
                _ = try? await NetworkManager.shared.trackEvent(
                    userId: self?.userId ?? "",
                    eventName: "quiz_completed",
                    sdkVersion: AdchainSdk.shared.getSDKVersion(),
                    category: "quiz",
                    properties: ["quiz_id": self?.quizId ?? ""]
                )
            }
            
            // Trigger quiz refresh
            AdchainQuiz.currentQuizInstance?.value?.refreshAfterCompletion()
            
            // Don't call onClosed() here - quiz completion doesn't mean WebView is closed
            // onClosed() should only be called when WebView is actually closing
            // Self.callback?.onClosed()  // REMOVED: Prevents duplicate callback invocation
        }
    }
    
    private func handleQuizStarted(data: [String: Any]?) {
        print("Quiz started")
        
        Task {
            _ = try? await NetworkManager.shared.trackEvent(
                userId: userId ?? "",
                eventName: "quiz_started",
                sdkVersion: AdchainSdk.shared.getSDKVersion(),
                category: "quiz",
                properties: ["quiz_id": quizId ?? ""]
            )
        }
    }
    
    private func handleMissionCompleted(data: [String: Any]?) {
        print("Mission completed")
        
        let missionId = data?["missionId"] as? String ?? ""
        
        DispatchQueue.main.async { [weak self] in
            Task {
                _ = try? await NetworkManager.shared.trackEvent(
                    userId: self?.userId ?? "",
                    eventName: "mission_completed",
                    sdkVersion: AdchainSdk.shared.getSDKVersion(),
                    category: "mission",
                    properties: ["mission_id": missionId]
                )
            }
            
            // Trigger mission refresh
            AdchainMission.currentMissionInstance?.refreshAfterCompletion()
            
            // DO NOT call onClosed() here
            // Mission completion should only trigger data refresh, not close the WebView
            // The WebView should remain open until user manually closes it
            // Self.callback?.onClosed() // Removed to prevent duplicate callback invocation
        }
    }
    
    private func handleGetUserInfo() {
        if let user = AdchainSdk.shared.getCurrentUser() {
            let userInfo = [
                "userId": user.userId,
                "gender": user.gender?.rawValue ?? "",
                "birthYear": user.birthYear ?? 0
            ] as [String : Any]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let script = """
                if (window.onUserInfoReceived) {
                    window.onUserInfoReceived(\(jsonString));
                }
                """
                webView.evaluateJavaScript(script)
            }
        }
    }
}

// MARK: - WKNavigationDelegate
extension AdchainOfferwallViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Page loaded successfully")
        // Polyfill already injected via WKUserScript at document start
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url?.absoluteString {
            // Check for special URLs
            if url.contains("adchain://close") {
                DispatchQueue.main.async { [weak self] in
                    self?.closeOfferwall()
                }
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView error: \(error.localizedDescription)")
        Self.callback?.onError("Failed to load offerwall: \(error.localizedDescription)")
    }
}

// MARK: - WKUIDelegate
extension AdchainOfferwallViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("JS Alert: \(message)")
        completionHandler()
    }
}

