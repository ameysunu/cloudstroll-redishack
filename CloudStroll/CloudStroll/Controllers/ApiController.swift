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
    
    func sendMemoryToApi(memory: Memory, completion: @escaping (Result<String, AFError>) -> Void){
        AF.request(
            apiEndpoint + "/memory",
            method: .post,
            parameters: memory,
            encoder: JSONParameterEncoder.default
        )
        .validate()
        .responseString { response in
            completion(response.result)
        }
    }
    
    func fetchMemories(for uid: String, completion: @escaping (Result<[Memory], AFError>) -> Void) {
        let endpoint = apiEndpoint + "/memoryById"
        let parameters: [String: String] = ["uid": uid]
        
        AF.request(endpoint, method: .get, parameters: parameters)
            .validate()
            .responseDecodable(of: [Memory].self) { response in
                print(response)
                completion(response.result)
            }
    }
    
    func fetchNearbyMemories(lat:Double, long: Double, completion: @escaping (Result<[Memory], AFError>) -> Void){
        let endpoint = apiEndpoint + "/memories/near?lat=\(lat)&lon=\(long)"
        AF.request(endpoint, method: .get)
            .validate()
            .responseDecodable(of: [Memory].self) { response in
                print(response)
                completion(response.result)
            }

    }
    
    func fetchAllMemories() async throws -> [Memory] {
        let endpoint = apiEndpoint + "/memories"
        
        let memories = try await AF.request(endpoint, method: .get)
            .validate()
            .serializingDecodable([Memory].self)
            .value
            
        return memories
    }
    
    func fetchTrends(
        from: Date,
        to: Date,
        completion: @escaping (Result<[String: [TrendPoint]], AFError>) -> Void
    ) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let url = apiEndpoint + "/memories/trends"
        let params: Parameters = [
            "from": df.string(from: from),
            "to":   df.string(from: to)
        ]

        AF.request(url, parameters: params)
          .validate()
          .responseDecodable(of: [String: [TrendPoint]].self) { response in
              debugPrint(response)
              
              if let data = response.data,
                 let raw = String(data: data, encoding: .utf8) {
                  print("⚙️ trends JSON object:\n\(raw)")
              }

              completion(response.result)
          }
    }


    
}
