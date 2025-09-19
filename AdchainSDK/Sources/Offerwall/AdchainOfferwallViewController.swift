import UIKit
import WebKit
import SystemConfiguration

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
    private var advertisingId: String = "00000000-0000-0000-0000-000000000000"
    
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
    
    // MARK: - Orientation Support
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
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
            AdchainLogger.w("AdchainOfferwallViewController", "No base URL provided")
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
        
        // Check network connectivity first
        if !isNetworkAvailable() {
            AdchainLogger.w("AdchainOfferwallViewController", "No network connection detected, showing offline UI")
            showOfflineUI()
            return
        }

        // For main WebView, get advertising ID first then load
        Task {
            // Get advertising ID
            advertisingId = await DeviceUtils.getAdvertisingId()

            // Build URL with advertising ID
            let finalUrl = buildOfferwallUrl(baseUrl)
            AdchainLogger.d("AdchainOfferwallViewController", "Loading offerwall URL: \(finalUrl)")

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
                    if !advertisingId.isEmpty {
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
        
        // 스크롤 뷰의 contentInsetAdjustmentBehavior 설정
        // .never 사용 - Safe Area 자동 조정 비활성화
        // React Native와의 충돌 방지 및 하단 버튼 고정을 위해 수동 제어
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        // 바운스 효과 설정 - 수직 스크롤은 iOS 네이티브 UX 유지
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true  // 콘텐츠 탄성 스크롤 복원
        webView.scrollView.alwaysBounceHorizontal = false  // 수평 바운스는 비활성화

        view.addSubview(webView)

        // Safe Area Layout Guide에 맞춰 constraints 설정
        // 상단은 Safe Area 적용, 하단은 view의 bottomAnchor 사용
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
        
        // Add IFA (advertising ID) - always has a value
        if !advertisingId.isEmpty {
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
        if !advertisingId.isEmpty {
            Task {
                let jsCode = "if(window.AdchainConfig) { window.AdchainConfig.ifa = '\(advertisingId)'; }"
                _ = try? await webView.evaluateJavaScript(jsCode)
            }
        }
        
        return components.url!.absoluteString
    }
    
    // MARK: - Close Methods
    private func closeOfferwall() {
        AdchainLogger.d("AdchainOfferwallViewController", "Closing offerwall")
        
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

    // MARK: - Network Checking
    private func isNetworkAvailable() -> Bool {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)

        guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else {
            return false
        }

        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return isReachable && !needsConnection
    }

    // MARK: - Offline UI
    private func showOfflineUI() {
        AdchainLogger.d("AdchainOfferwallViewController", "Showing offline UI")
        // Directly use the inline HTML for simplicity and reliability
        showBasicOfflineUI()
    }

    // Fallback: Show basic offline UI when bundle loading fails
    private func showBasicOfflineUI() {
        let offlineHtml = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    * {
                        margin: 0;
                        padding: 0;
                        box-sizing: border-box;
                    }
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', sans-serif;
                        background: #FFFFFF;
                        min-height: 100vh;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        padding: 20px;
                        -webkit-font-smoothing: antialiased;
                    }
                    .container {
                        background: white;
                        border-radius: 24px;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                        padding: 48px 32px;
                        max-width: 380px;
                        width: 100%;
                        text-align: center;
                        animation: slideUp 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);
                    }
                    @keyframes slideUp {
                        from {
                            opacity: 0;
                            transform: translateY(40px) scale(0.9);
                        }
                        to {
                            opacity: 1;
                            transform: translateY(0) scale(1);
                        }
                    }
                    .icon {
                        width: 90px;
                        height: 90px;
                        margin: 0 auto 24px;
                        background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                        border-radius: 50%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 42px;
                        box-shadow: 0 10px 30px rgba(245, 87, 108, 0.3);
                    }
                    h2 {
                        color: #2d3436;
                        font-size: 26px;
                        font-weight: 700;
                        margin-bottom: 12px;
                        letter-spacing: -0.5px;
                    }
                    p {
                        color: #636e72;
                        font-size: 17px;
                        line-height: 1.6;
                        margin-bottom: 32px;
                        font-weight: 400;
                    }
                    .buttons {
                        display: flex;
                        flex-direction: column;
                        gap: 12px;
                    }
                    button {
                        padding: 16px 24px;
                        font-size: 17px;
                        font-weight: 600;
                        border: none;
                        border-radius: 14px;
                        cursor: pointer;
                        transition: all 0.2s ease;
                        width: 100%;
                        -webkit-appearance: none;
                        position: relative;
                        overflow: hidden;
                    }
                    button:before {
                        content: '';
                        position: absolute;
                        top: 50%;
                        left: 50%;
                        width: 0;
                        height: 0;
                        border-radius: 50%;
                        background: rgba(255,255,255,0.3);
                        transform: translate(-50%, -50%);
                        transition: width 0.6s, height 0.6s;
                    }
                    button:active:before {
                        width: 300px;
                        height: 300px;
                    }
                    button:active {
                        transform: scale(0.98);
                    }
                    .btn-primary {
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);
                    }
                    .btn-secondary {
                        background: #f5f3f7;
                        color: #2d3436;
                    }
                    .loading {
                        display: none;
                        margin-top: 24px;
                    }
                    .loading.show {
                        display: block;
                    }
                    .spinner {
                        width: 32px;
                        height: 32px;
                        border: 3px solid #f3f3f3;
                        border-top: 3px solid #667eea;
                        border-radius: 50%;
                        animation: spin 1s cubic-bezier(0.68, -0.55, 0.265, 1.55) infinite;
                        margin: 0 auto;
                    }
                    @keyframes spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="icon">🌐</div>
                    <h2>연결할 수 없음</h2>
                    <p>인터넷 연결을 확인한 후<br>다시 시도해 주세요</p>
                    <div class="buttons">
                        <button class="btn-primary" onclick="handleClose()">닫기</button>
                    </div>
                    <div id="loading" class="loading">
                        <div class="spinner"></div>
                    </div>
                </div>
                <script>
                    function handleRetry() {
                        document.getElementById('loading').classList.add('show');
                        document.querySelectorAll('button').forEach(btn => btn.disabled = true);
                        setTimeout(() => {
                            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.adchainNative) {
                                window.webkit.messageHandlers.adchainNative.postMessage(JSON.stringify({type:'retry'}));
                            } else {
                                location.reload();
                            }
                        }, 300);
                    }
                    function handleClose() {
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.adchainNative) {
                            window.webkit.messageHandlers.adchainNative.postMessage(JSON.stringify({type:'close'}));
                        } else {
                            window.history.back();
                        }
                    }
                </script>
            </body>
            </html>
        """

        DispatchQueue.main.async { [weak self] in
            self?.webView.loadHTMLString(offlineHtml, baseURL: nil)
        }
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
            AdchainLogger.v("AdchainOfferwallViewController", "Received webkit message from \(message.name): \(jsonString)")
            handlePostMessage(jsonString)
        }
    }
    
    // MARK: - Message Handler (Android의 handlePostMessage와 완전 동일)
    private func handlePostMessage(_ jsonMessage: String) {
        guard let data = jsonMessage.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            AdchainLogger.w("AdchainOfferwallViewController", "Failed to parse JS message")
            return
        }
        
        let messageData = json["data"] as? [String: Any]
        
        AdchainLogger.v("AdchainOfferwallViewController", "Processing message type: \(type)")
        
        switch type {
        case "openWebView":
            handleOpenWebView(data: messageData)
        case "close":
            handleClose()
        case "retry":
            handleRetry()
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
        case "missionProgressed":
            handleMissionProgressed(data: messageData)
        case "getUserInfo":
            handleGetUserInfo()
        default:
            AdchainLogger.w("AdchainOfferwallViewController", "Unknown message type: \(type)")
        }
    }
    
    // MARK: - Individual Message Handlers
    private func handleOpenWebView(data: [String: Any]?) {
        guard let url = data?["url"] as? String, !url.isEmpty else {
            AdchainLogger.w("AdchainOfferwallViewController", "openWebView: No URL provided")
            return
        }
        
        AdchainLogger.d("AdchainOfferwallViewController", "Opening sub WebView: \(url)")
        
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
        AdchainLogger.d("AdchainOfferwallViewController", "Handling close message")

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

    private func handleRetry() {
        AdchainLogger.d("AdchainOfferwallViewController", "Handling retry message")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Check network availability
            if self.isNetworkAvailable() {
                // Reload the original URL if network is available
                if let baseUrlString = self.baseUrl,
                   let url = URL(string: baseUrlString) {
                    AdchainLogger.d("AdchainOfferwallViewController", "Retrying with URL: \(baseUrlString)")
                    self.webView?.load(URLRequest(url: url))
                } else {
                    AdchainLogger.w("AdchainOfferwallViewController", "No URL to retry")
                }
            } else {
                // If still no network, show offline UI again
                AdchainLogger.d("AdchainOfferwallViewController", "Network still unavailable, showing offline UI")
                self.showOfflineUI()
            }
        }
    }
    
    private func handleCloseOpenWebView(data: [String: Any]?) {
        guard let url = data?["url"] as? String, !url.isEmpty else {
            AdchainLogger.w("AdchainOfferwallViewController", "closeOpenWebView: No URL provided")
            return
        }
        
        AdchainLogger.d("AdchainOfferwallViewController", "Handling closeOpenWebView - isSubWebView: \(isSubWebView), url: \(url)")
        
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
            AdchainLogger.w("AdchainOfferwallViewController", "externalOpenBrowser: No URL provided")
            return
        }
        
        AdchainLogger.d("AdchainOfferwallViewController", "Opening external browser: \(urlString)")
        
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
                AdchainLogger.w("AdchainOfferwallViewController", "Cannot open URL: \(urlString)")
            }
        }
    }
    
    // Quiz-specific handlers
    private func handleQuizCompleted(data: [String: Any]?) {
        AdchainLogger.i("AdchainOfferwallViewController", "[iOS SDK - WebView] handleQuizCompleted 호출됨!")
        AdchainLogger.d("AdchainOfferwallViewController", "[iOS SDK - WebView] 받은 데이터: \(data ?? [:])")
        
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
            
            // Notify quiz completed with current quiz event
            if let quizInstance = AdchainQuiz.currentQuizInstance?.value,
               let quizEvent = AdchainQuiz.currentQuizEvent {
                AdchainLogger.d("AdchainOfferwallViewController", "[iOS SDK - WebView] Quiz 완료 알림...")
                quizInstance.notifyQuizCompleted(quizEvent)
                AdchainLogger.i("AdchainOfferwallViewController", "[iOS SDK - WebView] Quiz 완료 알림 완료!")
            } else {
                AdchainLogger.w("AdchainOfferwallViewController", "[iOS SDK - WebView] Quiz instance 또는 event를 찾을 수 없음")
            }
            
            // Don't call onClosed() here - quiz completion doesn't mean WebView is closed
            // onClosed() should only be called when WebView is actually closing
            // Self.callback?.onClosed()  // REMOVED: Prevents duplicate callback invocation
        }
    }
    
    private func handleQuizStarted(data: [String: Any]?) {
        AdchainLogger.d("AdchainOfferwallViewController", "Quiz started")
        
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
        AdchainLogger.i("AdchainOfferwallViewController", "Mission completed")

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

            // Notify mission completed with current mission
            if let missionInstance = AdchainMission.currentMissionInstance,
               let currentMission = AdchainMission.currentMission {
                AdchainLogger.d("AdchainOfferwallViewController", "[iOS SDK - WebView] Mission 완료 알림...")
                missionInstance.onMissionCompleted(currentMission)
                AdchainLogger.i("AdchainOfferwallViewController", "[iOS SDK - WebView] Mission 완료 알림 완료!")
            } else {
                AdchainLogger.w("AdchainOfferwallViewController", "[iOS SDK - WebView] Mission instance 또는 mission을 찾을 수 없음")
            }

            // DO NOT call onClosed() here
            // Mission completion should only trigger data refresh, not close the WebView
            // The WebView should remain open until user manually closes it
            // Self.callback?.onClosed() // Removed to prevent duplicate callback invocation
        }
    }

    private func handleMissionProgressed(data: [String: Any]?) {
        AdchainLogger.d("AdchainOfferwallViewController", "Mission progressed")

        let missionId = data?["missionId"] as? String ?? ""

        DispatchQueue.main.async { [weak self] in
            Task {
                _ = try? await NetworkManager.shared.trackEvent(
                    userId: self?.userId ?? "",
                    eventName: "mission_progressed",
                    sdkVersion: AdchainSdk.shared.getSDKVersion(),
                    category: "mission",
                    properties: [
                        "mission_id": missionId
                    ]
                )
            }

            // Notify mission progressed with current mission (without progress parameter)
            if let missionInstance = AdchainMission.currentMissionInstance,
               let currentMission = AdchainMission.currentMission {
                AdchainLogger.d("AdchainOfferwallViewController", "[iOS SDK - WebView] Mission 진행 알림...")
                missionInstance.onMissionProgressed(currentMission)
                AdchainLogger.i("AdchainOfferwallViewController", "[iOS SDK - WebView] Mission 진행 알림 완료!")
            } else {
                AdchainLogger.w("AdchainOfferwallViewController", "[iOS SDK - WebView] Mission instance 또는 mission을 찾을 수 없음")
            }

            // DO NOT call onClosed() here
            // Mission progress should only trigger UI update, not close the WebView
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
        AdchainLogger.d("AdchainOfferwallViewController", "Page loaded successfully")
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
        AdchainLogger.e("AdchainOfferwallViewController", "WebView error: \(error.localizedDescription)", error)

        let nsError = error as NSError
        // 취소된 요청은 무시
        guard nsError.code != NSURLErrorCancelled else { return }

        // 네트워크 오류 시 오프라인 페이지 표시
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorTimedOut:
            showOfflineUI()
        default:
            Self.callback?.onError("Failed to load offerwall: \(error.localizedDescription)")
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        AdchainLogger.e("AdchainOfferwallViewController", "WebView provisional navigation error: \(error.localizedDescription)", error)

        let nsError = error as NSError

        // 취소된 요청 무시
        guard nsError.code != NSURLErrorCancelled else { return }

        // 네트워크 오류 시 오프라인 페이지 표시
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorTimedOut,
             NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost:
            showOfflineUI()
        default:
            Self.callback?.onError("Failed to load offerwall: \(error.localizedDescription)")
        }
    }
}

// MARK: - WKUIDelegate
extension AdchainOfferwallViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        AdchainLogger.d("AdchainOfferwallViewController", "JS Alert: \(message)")
        completionHandler()
    }
}

