//
//  AuthManager.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import Foundation
import FirebaseAuth

final class AuthManager: ObservableObject {
    @Published var userId: String? = "gizem-demo"
    
    static let shared = AuthManager()
    
    private init() {
        if let currentUid = Auth.auth().currentUser?.uid {
            self.userId = currentUid
        } else {
            self.userId = "gizem-demo"
            signInAnonymously()
        }
    }
    
    private func signInAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                print("Anonymous sign-in failed:", error)
                return
            }
            self?.userId = result?.user.uid
        }
    }
}

