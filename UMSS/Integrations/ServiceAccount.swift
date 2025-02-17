//
//  ServiceAccount.swift
//  UMSS
//
//  Created by Omar Syed on 2/9/25.
//


import Foundation
import SwiftJWT

// MARK: - Service Account Model
public struct ServiceAccount: Codable {
    public let type: String
    public let project_id: String
    public let private_key_id: String
    public let private_key: String
    public let client_email: String
    public let client_id: String
    public let auth_uri: String
    public let token_uri: String
    public let auth_provider_x509_cert_url: String
    public let client_x509_cert_url: String
}

// MARK: - JWT Claims
public struct MyClaims: Claims {
    public let iss: String       // issuer: the service account email
    public let scope: String     // requested scopes
    public let aud: String       // token URI
    public let exp: Date         // expiration time
    public let iat: Date         // issued at time
}

// MARK: - Service Account Helpers
public func getServiceAccount() -> ServiceAccount? {
    if let url = Bundle.main.url(forResource: "ServiceAccount", withExtension: "json") {
        print("ServiceAccount.json found at: \(url)")
    } else {
        print("ServiceAccount.json not found in bundle!")
    }
    guard let url = Bundle.main.url(forResource: "ServiceAccount", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let account = try? JSONDecoder().decode(ServiceAccount.self, from: data) else {
        return nil
    }
    return account
}

public func getAccessToken(completion: @escaping (String?) -> Void) {
    guard let account = getServiceAccount() else {
        print("Failed to load service account credentials.")
        completion(nil)
        return
    }
    
    let now = Date()
    let exp = now.addingTimeInterval(3600) // token valid for 1 hour
    let claims = MyClaims(iss: account.client_email,
                          scope: "https://www.googleapis.com/auth/drive.file",
                          aud: account.token_uri,
                          exp: exp,
                          iat: now)
    
    // Prepare the JWT signer using RS256.
    let privateKey = account.private_key.replacingOccurrences(of: "\\n", with: "\n")
    guard let keyData = privateKey.data(using: .utf8) else {
        completion(nil)
        return
    }
    let jwtSigner = JWTSigner.rs256(privateKey: keyData)
    
    var jwt = JWT(claims: claims)
    let jwtEncoder = JWTEncoder(jwtSigner: jwtSigner)
    do {
        let signedJWT = try jwtEncoder.encodeToString(jwt)
        
        // Prepare POST request to get an access token.
        guard let url = URL(string: account.token_uri) else {
            print("Invalid token URI.")
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyParams = [
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": signedJWT
        ]
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error getting access token: \(error)")
                completion(nil)
                return
            }
            guard let data = data else {
                print("No data in access token response.")
                completion(nil)
                return
            }
            if let responseStr = String(data: data, encoding: .utf8) {
                print("Access token raw response: \(responseStr)")
            }
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let accessToken = json["access_token"] as? String {
                completion(accessToken)
            } else {
                print("Failed to parse access token JSON.")
                completion(nil)
            }
        }.resume()
        
    } catch {
        print("Error encoding JWT: \(error)")
        completion(nil)
    }
}
