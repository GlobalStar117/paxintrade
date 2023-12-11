import SwiftUI
import WebKit
import UIKit


struct ContentView: View {
    @State private var isWebsiteLoaded = false
    @State private var loadingProgress: Float = 0.0
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            WebView(url: URL(string: "https://paxintrade.com")!, isWebsiteLoaded: $isWebsiteLoaded, loadingProgress: $loadingProgress)

            if !isWebsiteLoaded {
                    VStack {
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                Image("logo-1024") // Assuming you have an image named "logo-1024" in your assets
                                    .resizable()
                                    .frame(width: 150, height: 150)
                                    .padding(.top, 50) // Add padding to the top of the image

                                HStack {
                                    Spacer()

                                    ProgressView(value: loadingProgress)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(height: 2)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, geometry.size.width * 0.15) // Apply left and right padding of 15%

                                    Spacer()
                                }

                            Spacer()
                            }.onAppear {

                                printStoredCookies()
                                withAnimation(.easeIn(duration: 0.5)) {
                                    isAnimating = true // Start the animation
                                }
                            }

                        }
                    }.background(Color.white)

            }
        }
    }
}

// New: Method to print the stored cookies in the console
private func printStoredCookies() {
    let storedCookies = HTTPCookieStorage.shared.cookies ?? []
    print("Stored Cookies:")
    if storedCookies.isEmpty {
        print("No cookies found.")
    } else {
        print(storedCookies)

        for cookie in storedCookies {
            print("Name: \(cookie.name), Value: \(cookie.value)")
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isWebsiteLoaded: Bool
    @Binding var loadingProgress: Float
    var hasRedirectedToProfile = false


    func makeCoordinator() -> Coordinator {
        Coordinator(isWebsiteLoaded: $isWebsiteLoaded, loadingProgress: $loadingProgress)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isWebsiteLoaded: Bool
        @Binding var loadingProgress: Float
        var hasRedirectedToProfile = false



        init(isWebsiteLoaded: Binding<Bool>, loadingProgress: Binding<Float>) {
            _isWebsiteLoaded = isWebsiteLoaded
            _loadingProgress = loadingProgress
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            loadingProgress = 0.1
            handleReceivedCookies(webView)
            if !hasRedirectedToProfile {
                let cookieStorage = HTTPCookieStorage.shared
                let currentTime = Date()
                let storedCookies = HTTPCookieStorage.shared.cookies ?? []
                
                for cookie in storedCookies {
                       if cookie.name == "access_token" && !cookie.value.isEmpty {
                           // Проверяем срок действия куки
                           if let expiryDate = cookie.expiresDate, expiryDate <= currentTime {
                               // Куки устарели, удаляем их
                               cookieStorage.deleteCookie(cookie)
                               webView.load(URLRequest(url: URL(string: "https://paxintrade.com/")!))
                           } else {
                               // Куки действительны, выполняем перенаправление
                               webView.load(URLRequest(url: URL(string: "https://paxintrade.com/profile/blog/new")!))
                               hasRedirectedToProfile = true
                               return
                           }
                       }
                   }
                
//                if storedCookies.contains(where: { $0.name == "access_token" && !$0.value.isEmpty }) {
//                     webView.load(URLRequest(url: URL(string: "https://paxintrade.com/profile/blog/new")!))
//                     hasRedirectedToProfile = true
//                     return
//                 }
                
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isWebsiteLoaded = true
            }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let urlString = url.absoluteString
         
            if urlString.hasPrefix("tg://") {
                UIApplication.shared.open(url, options: [:]) { success in
                    if !success {
                        print("Failed to open Telegram app.")
                    }
                }

                decisionHandler(.cancel)
                return
            }


            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loadingProgress = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isWebsiteLoaded = true
            }

            // Check if the cookie is found
            let storedCookies = HTTPCookieStorage.shared.cookies ?? []
            _ = storedCookies.contains { cookie in
                return cookie.name == "access_token" // Replace "YourCookieName" with the actual name of your cookie
            }

        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            loadingProgress = 0.0
            handleReceivedCookies(webView)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isWebsiteLoaded = true
            }
        }

        // New: Handle received cookies
        private func handleReceivedCookies(_ webView: WKWebView) {
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    // Store the cookie in the shared HTTPCookieStorage
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
            }
        }
        
        private func handleRemoveCookies(_ webView: WKWebView) {
            let cookieJar = HTTPCookieStorage.shared

            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    // Remove any existing cookies with the same name
                    if let existingCookie = cookieJar.cookies(for: webView.url!)?.first(where: { $0.name == cookie.name }) {
                        cookieJar.deleteCookie(existingCookie)
                    }
                }
            }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            loadingProgress = 0.0
     
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isWebsiteLoaded = true
            }
        }

        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
            loadingProgress = 0.4
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
