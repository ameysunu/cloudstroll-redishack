//
//  SecretsController.swift
//  CloudStroll
//
//  Created by Amey Sunu on 01/08/2025.
//

import Foundation

class SecretsController: SecretsProtocol {
    
    func getSecret(forKey key: String) -> String {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            fatalError("Could not find Info.plist. This should not happen.")
        }
        
        guard let secret = infoDictionary[key] as? String else {
            fatalError("Could not find secret for key '\(key)' in Info.plist. Check your configuration.")
        }
        
        if secret.starts(with: "$(") {
            fatalError("Secret for key '\(key)' is a placeholder. Make sure your xcconfig is linked correctly.")
        }
        
        return secret
    }
}
