//
//  AuthManager.swift
//  thelongevityapp
//
//  Created by Gizem Demir on 4.12.2025.
//

import Foundation
import FirebaseAuth

/// Centralized Firebase Auth wrapper. Handles email/password sign-up & sign-in,
/// exposes current uid, and provides fresh ID tokens for APIClient.
@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var currentUser: User?
    
    static let shared = AuthManager()
    
    private init() {
        currentUser = Auth.auth().currentUser
    }
    
    var uid: String? {
        currentUser?.uid
    }
    
    /// Returns whether the current user's email is verified.
    /// Note: Email verification is NOT required for app usage, this is informational only.
    var isEmailVerified: Bool {
        currentUser?.isEmailVerified ?? false
    }
    
    /// Reloads the current user to refresh email verification status.
    func reloadUser() async throws {
        try await currentUser?.reload()
        currentUser = Auth.auth().currentUser
    }
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        currentUser = result.user
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUser = result.user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }
    
    /// Returns a fresh ID token for protected API calls (always force-refresh).
    func getIDToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.missingAuthToken
        }
        return try await user.getIDTokenResult(forcingRefresh: true).token
    }
}

