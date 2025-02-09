import Foundation

public enum DriveUploaderError: Error {
    case fileDataUnavailable
    case invalidURL
    case uploadFailed(String)
    case invalidResponse
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

public func uploadFileToDrive(fileURL: URL,
                              accessToken: String,
                              folderID: String,
                              completion: @escaping (Result<String, Error>) -> Void) {
    // Get the file data from the file URL.
    guard let fileData = try? Data(contentsOf: fileURL) else {
        completion(.failure(DriveUploaderError.fileDataUnavailable))
        return
    }
    
    let boundary = "Boundary-\(UUID().uuidString)"
    var body = Data()
    
    // Prepare the metadata dictionary.
    let metadata: [String: Any] = [
        "name": fileURL.lastPathComponent,
        "parents": [folderID]
    ]
    
    // Convert metadata to JSON data.
    guard let metadataData = try? JSONSerialization.data(withJSONObject: metadata, options: []) else {
        completion(.failure(DriveUploaderError.uploadFailed("Failed to serialize metadata.")))
        return
    }
    
    // Append the metadata part.
    body.append("--\(boundary)\r\n")
    body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n")
    body.append(metadataData)
    body.append("\r\n")
    
    // Append the file data part.
    let mimeType = "application/octet-stream"  // Adjust if needed.
    body.append("--\(boundary)\r\n")
    body.append("Content-Type: \(mimeType)\r\n\r\n")
    body.append(fileData)
    body.append("\r\n")
    
    // End boundary.
    body.append("--\(boundary)--\r\n")
    
    // Prepare the URL.
    guard let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id&supportsAllDrives=true") else {
        completion(.failure(DriveUploaderError.invalidURL))
        return
    }
    
    // Build the request.
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.httpBody = body
    
    // Perform the upload.
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status code: \(httpResponse.statusCode)")
        }
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data else {
            completion(.failure(DriveUploaderError.invalidResponse))
            return
        }
        if let responseStr = String(data: data, encoding: .utf8) {
            print("Raw response: \(responseStr)")
        }
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let fileID = json["id"] as? String {
            completion(.success(fileID))
        } else if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let errorDict = json["error"] as? [String: Any] {
            completion(.failure(DriveUploaderError.uploadFailed("\(errorDict)")))
        } else {
            completion(.failure(DriveUploaderError.invalidResponse))
        }
    }.resume()
}
