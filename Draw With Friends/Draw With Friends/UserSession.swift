//
//  UserSession.swift
//  Draw With Friends
//
//  Created on 10/11/2025.
//

import Foundation

class UserSession {
    static let shared = UserSession()
    
    let userId: String
    
    private init() {
        // Generate once and keep for entire app session
        self.userId = UUID().uuidString
    }
}


