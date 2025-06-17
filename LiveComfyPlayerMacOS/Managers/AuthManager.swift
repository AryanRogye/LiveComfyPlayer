//
//  AuthManager.swift
//  LiveComfyPlayer
//
//  Created by Aryan Rogye on 6/13/25.
//

import Cocoa

import AuthenticationServices

@MainActor
final class AuthManager : ObservableObject {
    static let shared = AuthManager()
    
    @Published internal var isUserSignedIn: Bool = false
    @Published internal var userID: String?
    @Published internal var fullName: String? = nil
    @Published internal var email: String?
    
    
    init() {
        getUserAuthState()
    }    
}

extension AuthManager {
    
    @MainActor
    public func handleUserCredentials(_ credential: ASAuthorizationAppleIDCredential) {
        if let name = credential.fullName?.formatted() {
            fullName = name
        } else {
            fullName = "Unknown"
        }
        
        if let email = credential.email {
            self.email = email
        } else {
            self.email = "Unavailable"
        }
        self.userID = credential.user
        
        saveUserAuthState(credential)
        isUserSignedIn = true
    }
    
    @MainActor
    private func getUserAuthState() {
        let defaults = UserDefaults.standard
        
        if let userID = defaults.string(forKey: "appleUserID"),
           let email = defaults.string(forKey: "appleUserEmail"),
           let fullName = defaults.string(forKey: "appleUserFullName") {
            
            self.userID = userID
            self.email = email
            self.fullName = fullName
            
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                DispatchQueue.main.async {
                    switch state {
                    case .revoked, .notFound:
                        self.isUserSignedIn = false
                    case .authorized, .transferred:
                        self.isUserSignedIn = true
                    @unknown default:
                        self.isUserSignedIn = false
                    }
                }
            }
            
        } else {
            DispatchQueue.main.async {
                self.isUserSignedIn = false
            }
        }
    }
    
    @MainActor
    public func signOut() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "appleUserID")
        defaults.removeObject(forKey: "appleUserFullName")
        defaults.removeObject(forKey: "appleUserEmail")
        
        userID = nil
        fullName = nil
        email = nil
        isUserSignedIn = false
    }
    
    private func saveUserAuthState(_ credential: ASAuthorizationAppleIDCredential) {
        let defaults = UserDefaults.standard
        
        defaults.set(credential.user, forKey: "appleUserID")
        if let name = credential.fullName?.formatted() {
            defaults.set(name, forKey: "appleUserFullName")
        }
        if let email = credential.email {
            defaults.set(email, forKey: "appleUserEmail")
        }
    }
}
