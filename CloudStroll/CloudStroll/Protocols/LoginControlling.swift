//
//  LoginControlling.swift
//  CloudStroll
//
//  Created by Amey Sunu on 31/07/2025.
//
import Foundation
import AuthenticationServices
import Combine

protocol LoginControlling: ObservableObject {
    
    var userIdentifier: String? { get }
    
    var userEmail: String? { get }
    
    var userFullName: String? { get }
    
    var errorMessage: String? { get }
    
    var isSignedIn: Bool { get }

    func prepareRequest(_ request: ASAuthorizationAppleIDRequest)
    
    func handleSignInSuccess(_ authorization: ASAuthorization)
    
    func handleSignInFailure(_ error: Error)
}
