//
//  ApiController.swift
//  CloudStroll
//
//  Created by Amey Sunu on 01/08/2025.
//

import Foundation
import Alamofire

class ApiController {
    private var apiEndpoint: String = ""
    
    init() {
        let secretsCtrl = SecretsController()
        apiEndpoint = "https://" + secretsCtrl.getSecret(forKey: "API_ENDPOINT")
        print(apiEndpoint)
    }
    
    func apiHealthCheck(completion: @escaping (Result<String, AFError>) -> Void){
        AF.request(apiEndpoint)
            .responseString { response in
                completion(response.result)
            }
    }
    
}
