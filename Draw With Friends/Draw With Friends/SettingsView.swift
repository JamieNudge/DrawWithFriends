//
//  SettingsView.swift
//  Draw With Friends
//

import SwiftUI

struct SettingsView: View {
    var onShowHowItWorks: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var pageToOpen: WebPage?
    
    private let privacyURL = URL(string: "https://jamienudge.github.io/DrawWithFriends/privacy.html")!
    private let supportURL = URL(string: "https://jamienudge.github.io/DrawWithFriends/support.html")!
    
    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            onShowHowItWorks()
                        }
                    } label: {
                        Label("How it works", systemImage: "questionmark.circle")
                    }
                }
                
                Section {
                    Button {
                        pageToOpen = WebPage(url: privacyURL)
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Button {
                        pageToOpen = WebPage(url: supportURL)
                    } label: {
                        Label("Support", systemImage: "envelope")
                    }
                }
                
                Section {
                    Text(versionText)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $pageToOpen) { page in
                InAppBrowser(url: page.url)
                    .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    SettingsView(onShowHowItWorks: {})
}
