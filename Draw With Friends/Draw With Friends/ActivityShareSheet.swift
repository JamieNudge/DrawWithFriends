//
//  ActivityShareSheet.swift
//  Draw With Friends
//

import SwiftUI
import UIKit

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

/// Presents UIActivityViewController after the SwiftUI sheet is actually on-screen.
/// Presenting it as the sheet's root (or on the first layout pass) often yields a blank share sheet.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: () -> Void = {}
    
    func makeUIViewController(context: Context) -> SharePresenter {
        let presenter = SharePresenter()
        presenter.items = items
        presenter.onComplete = onComplete
        return presenter
    }
    
    func updateUIViewController(_ uiViewController: SharePresenter, context: Context) {
        uiViewController.items = items
        uiViewController.onComplete = onComplete
        uiViewController.presentShareIfNeeded()
    }
}

final class SharePresenter: UIViewController {
    var items: [Any] = []
    var onComplete: () -> Void = {}
    private var didPresent = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentShareIfNeeded()
    }
    
    func presentShareIfNeeded() {
        guard !didPresent, !items.isEmpty, view.window != nil else { return }
        didPresent = true
        
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: 8, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        activity.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.onComplete()
        }
        present(activity, animated: true)
    }
}
