//
//  InAppBrowser.swift
//  Draw With Friends
//

import SwiftUI
import SafariServices

struct WebPage: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

struct InAppBrowser: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.dismissButtonStyle = .close
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
