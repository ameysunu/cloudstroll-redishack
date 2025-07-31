//
//  LoginController.swift
//  CloudStroll
//
//  Created by Amey Sunu on 28/07/2025.
//

import AuthenticationServices
import CryptoKit
import Combine

class LoginController: LoginControlling {
    
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var userFullName: String?
    @Published var errorMessage: String?
    @Published var isSignedIn = false
    
    fileprivate var currentNonce: String?
    
    func prepareRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        self.currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    func handleSignInSuccess(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Received an invalid credential type."
            return
        }

        guard let nonce = currentNonce,
              let idToken = appleIDCredential.identityToken,
              let idTokenString = String(data: idToken, encoding: .utf8),
              verifyNonce(idTokenString: idTokenString, expectedNonce: nonce) else {
            errorMessage = "Invalid nonce. This may be a replay attack."
            return
        }

        self.currentNonce = nil
        self.userIdentifier = appleIDCredential.user

        if let fullName = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            self.userFullName = formatter.string(from: fullName)
        }

        if let email = appleIDCredential.email {
            self.userEmail = email
        }

        self.isSignedIn = true
        print("Sign in successful! User: \(self.userIdentifier ?? "N/A")")
    }
    
    func handleSignInFailure(_ error: Error) {
        guard let authError = error as? ASAuthorizationError else {
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print(errorMessage!)
            return
        }
        
        switch authError.code {
        case .canceled:
            errorMessage = "The sign-in process was canceled."
        case .failed, .invalidResponse, .notHandled, .unknown:
            errorMessage = "Sign in failed. Please try again."
        @unknown default:
            errorMessage = "An unknown error occurred."
        }
        print("Sign in failed: \(errorMessage ?? "Unknown error")")
    }
    

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate random bytes. OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
    
    private func verifyNonce(idTokenString: String, expectedNonce: String) -> Bool {
        guard let payloadData = decodeJWTPayload(jwt: idTokenString),
              let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any],
              let nonceFromToken = payload["nonce"] as? String else {
            return false
        }
        return nonceFromToken == expectedNonce
    }
    
    private func decodeJWTPayload(jwt: String) -> Data? {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        var base64String = segments[1]
        
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64String)
    }
}
