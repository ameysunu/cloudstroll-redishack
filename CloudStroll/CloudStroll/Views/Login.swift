//
//  Login.swift
//  CloudStroll
//
//  Created by Amey Sunu on 28/07/2025.
//

import SwiftUI
import AuthenticationServices

struct Login: View {
    
    @ObservedObject var loginCtrl: LoginController
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("Cloud Stroll")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Log your memories and adventures")
                .foregroundStyle(.secondary)

            Spacer()
            
            TextField("Email", text: $loginCtrl.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                        
            SecureField("Password", text: $loginCtrl.password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
            Button(action: {
                            loginCtrl.signInWithEmail()
                        }) {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
            
            Divider()
            
            Button(action: {
                loginCtrl.createAccountWithEmail()
            }) {
                Text("Create an account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            .controlSize(.large)
            
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
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
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
