import UIKit
import WebKit

final class GuideViewController: UIViewController {
    private let webView = WKWebView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "使用说明"
        setupWebView()
        loadGuide()
    }

    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadGuide() {
        guard let fileURL = Bundle.main.url(forResource: "user-guide", withExtension: "html") else {
            let fallback = "<html><body><h2>未找到说明文档</h2></body></html>"
            webView.loadHTMLString(fallback, baseURL: nil)
            return
        }

        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
    }
}
