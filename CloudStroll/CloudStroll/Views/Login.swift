//
//  Login.swift
//  CloudStroll
//
//  Created by Amey Sunu on 28/07/2025.
//

import SwiftUI
import AuthenticationServices

struct Login: View {
    
    @StateObject private var loginCtrl = LoginController()
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("Cloud Stroll")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Log your memories and adventures")
                .foregroundStyle(.secondary)

            Spacer()
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    loginCtrl.prepareRequest(request)
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        loginCtrl.handleSignInSuccess(authorization)
                    case .failure(let error):
                        loginCtrl.handleSignInFailure(error)
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 55)
            .cornerRadius(10)
            .padding(.horizontal)
            
            if let errorMessage = loginCtrl.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
            
            Text("By continuing, you agree to our Terms of Service and Privacy Policy.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
        }
        .padding()
    }
}

#Preview {
    Login()
}
