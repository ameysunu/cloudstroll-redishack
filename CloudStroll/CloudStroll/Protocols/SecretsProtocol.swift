//
//  SecretsProtocol.swift
//  CloudStroll
//
//  Created by Amey Sunu on 01/08/2025.
//

import Foundation

protocol SecretsProtocol {
    func getSecret(forKey key: String) throws -> String
}
